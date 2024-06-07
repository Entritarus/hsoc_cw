#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include <signal.h>
#include <pthread.h>
#include "timer.h"
#include "constants.h"
#include "timer.h"
#include "util.h"

/* msgdma / cma APIs */
#include "msgdma_api.h"
#include "cma_api.h"

#define _I(fmt, args...) printf(fmt "\n", ##args)
#define _W(fmt, args...) printf("WARNING: " fmt "\n", ##args)
#define _E(fmt, args...) printf("ERROR: " fmt "\n", ##args)
#define _D(fmt, args...)

#define FIXED_FRAME_SIZE(img) (img->width * img->height * 4)
// this macro is required due to the architeture of the component
// it accepts 32 bit words, so image size is fixed to 4 bytes

/* single file library for loading images */
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

/* single file library for sabing images */
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

typedef struct {
    int      width;
    int      height;
    int      channels;
    uint8_t *data;
} frame_t;

typedef enum {
    EN_SHOW,
    STOP_SHOW
} vga_state_t;

typedef struct {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
} color_t;

/* globals */
msgdma_device_t msgdma_vga;
vga_state_t vga_state;
frame_t frame;

/******************** FPGA-related API ********************/
void fpga_vga(frame_t *frame_in){
    struct msgdma_dscr dscr;

    dscr.read_addr  = cma_get_phy_addr(frame_in->data);
    dscr.write_addr = 0x0;
    dscr.length     = FIXED_FRAME_SIZE(frame_in);
    dscr.control    = MSGDMA_DSCR_GO | MSGDMA_DSCR_TRANSFER_COMPLETE_IRQ_MASK;

    write_standard_descriptor(msgdma_vga, &dscr);
}

/******************** frame-related API ********************/
void frame_init(frame_t *frame) {
  frame->width = IMAGE_MAX_WIDTH;
  frame->height = IMAGE_MAX_HEIGHT;
  frame->channels = 4;
  frame->data = (uint8_t*)cma_alloc_noncached(FIXED_FRAME_SIZE(frame));
}

void frame_deinit(frame_t *frame) {
  cma_free(frame->data);
}

int image_load(frame_t *frame, const char *fname) {
  int img_width;
  int img_height;
  int img_channels;
  uint8_t *img_data;
  
  img_data = stbi_load(fname, &img_width, &img_height, &img_channels, 0);
  if (img_data == NULL) {
    _E("Image read error");
    return -1;
  }
  
  if (img_channels == 1) {
    for (int y = 0; y < frame->height; y++)
      for(int x = 0; x < frame->width; x++)
        if (x < img_width && y < img_height) {
          frame->data[4*(y*frame->width+x)+0] = img_data[y*img_width+x];
          frame->data[4*(y*frame->width+x)+1] = img_data[y*img_width+x];
          frame->data[4*(y*frame->width+x)+2] = img_data[y*img_width+x];
          frame->data[4*(y*frame->width+x)+3] = 0;
        }
  } else if (img_channels == 3) {
    for (int y = 0; y < frame->height; y++)
      for(int x = 0; x < frame->width; x++)
        if (x < img_width && y < img_height) {
          frame->data[4*(y*frame->width+x)+0] = img_data[3*(y*img_width+x)+0];
          frame->data[4*(y*frame->width+x)+1] = img_data[3*(y*img_width+x)+1];
          frame->data[4*(y*frame->width+x)+2] = img_data[3*(y*img_width+x)+2];
          frame->data[4*(y*frame->width+x)+3] = 0;
        }
  } else if (img_channels == 4) {
    for (int y = 0; y < frame->height; y++)
      for(int x = 0; x < frame->width; x++)
        if (x < img_width && y < img_height) {
          frame->data[4*(y*frame->width+x)+0] = img_data[4*(y*img_width+x)+0];
          frame->data[4*(y*frame->width+x)+1] = img_data[4*(y*img_width+x)+1];
          frame->data[4*(y*frame->width+x)+2] = img_data[4*(y*img_width+x)+2];
          frame->data[4*(y*frame->width+x)+3] = 0;
        }
  } else {
    _I("The number of channels is not supported");
  }
  
  free(img_data);
  return 0;
}


void *frame_show(void *frame) {
  while(vga_state == EN_SHOW) {
    fpga_vga((frame_t*)frame);
  }
  pthread_exit(NULL);
}

void *frame_gen(void *frame) {
  color_t color;
  int x, y;
  int index;
  while(vga_state == EN_SHOW) {
    color.red = rand()%256;
    color.green = rand()%256;
    color.blue = rand()%256;
    x = rand()%((frame_t*)frame)->width;
    y = rand()%((frame_t*)frame)->height;
    index = 4*(y*IMAGE_MAX_WIDTH + x);
    ((frame_t*)frame)->data[index+0] = color.red;
    ((frame_t*)frame)->data[index+1] = color.green;
    ((frame_t*)frame)->data[index+2] = color.blue;
  }
  pthread_exit(NULL);
}


// ****** utility functions ******
void print_help(const char *exec){
  _I("USAGE:");
  _I("\n%s <image name>", exec);
}

void init() {
  _I("Initializing CMA, DMAs APIs");
  msgdma_vga    = msgdma_init("/dev/msgdma0");
  enable_global_interrupt_mask(msgdma_vga);

  cma_init();
  
  _I("Initializing frame");
  frame_init(&frame);

  vga_state = EN_SHOW;
}

void deinit() {
  _I("Deinitializing CMA, DMAs APIs");
  cma_release();
  msgdma_release(msgdma_vga);

  _I("Deinitializing frame");
  frame_deinit(&frame);
}

void signal_handler() {
  _I("Catched SIGINT");
  vga_state = STOP_SHOW;
}


int main(int argc, char *argv[])
{
  pthread_t showing_thread;
  pthread_t drawing_thread;

  init();
  signal(SIGINT, signal_handler);


  if(argc < 2){
    pthread_create(&drawing_thread, NULL, frame_gen, (void*)&frame);
  } else {
    _I("Loading image...");
    if(image_load(&frame, argv[1]) == -1){
      _E("Failed to load image");
      deinit();
      return -1;
    }
  }

  pthread_create(&showing_thread, NULL, frame_show, (void*)&frame);

  pthread_join(showing_thread, NULL);
  if (argc == 1)
    pthread_join(drawing_thread, NULL);

  


  deinit();


  return 0;
}
