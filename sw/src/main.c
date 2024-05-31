#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include "timer.h"

/* msgdma / cma APIs */
#include "msgdma_api.h"
#include "cma_api.h"

/* single file library for loading images */
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

/* single file library for sabing images */
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// print utilities
#define _I(fmt,args...)  printf(fmt "\n", ##args)
#define _W(fmt,args...)  printf("WARNING: " fmt "\n", ##args)
#define _E(fmt,args...)  printf("ERROR: " fmt "\n", ##args)
#define _D(fmt,args...)

#define IMAGE_SIZE(img) (img->width * img->height * img->channels)
#define FIXED_IMAGE_SIZE(img) (img->width * img->height * 4)
// this macro is required due to the architeture of the component
// it accepts 32 bit words, so image size is fixed to 4 bytes

typedef struct {
    int      width;
    int      height;
    int      channels;
    uint8_t *data;
} image_t;


/* globals */
msgdma_device_t msgdma_vga;

/******************** FPGA-related API ********************/
void fpga_vga(image_t *imageIn){
    struct msgdma_dscr dscr;

    dscr.read_addr  = cma_get_phy_addr(imageIn->data);
    dscr.write_addr = 0x0;
    dscr.length     = FIXED_IMAGE_SIZE(imageIn);
    dscr.control    = MSGDMA_DSCR_GO | MSGDMA_DSCR_TRANSFER_COMPLETE_IRQ_MASK;

    write_standard_descriptor(msgdma_vga, &dscr);
}


/******************** Image API ********************/
int image_load(image_t *image, const char *fname){
    uint8_t *data_cma;

    image->data = stbi_load(fname, &image->width, &image->height, &image->channels, 0);
    if(image->data == NULL){
        _E("Failed to load image");
        return -1;
    }

    data_cma = (uint8_t*)cma_alloc_noncached(FIXED_IMAGE_SIZE(image));

    if(image->channels == 1){
        for(int i=0; i<image->height*image->width; i++){
            data_cma[4*i+0] = image->data[i];
            data_cma[4*i+1] = image->data[i];
            data_cma[4*i+2] = image->data[i];
            data_cma[4*i+3] = 0;
        }
    } else if(image->channels == 3){
        for(int i=0; i<image->height*image->width; i++){
            data_cma[4*i+0] = image->data[3*i+0];
            data_cma[4*i+1] = image->data[3*i+1];
            data_cma[4*i+2] = image->data[3*i+2];
            data_cma[4*i+3] = 0;
        }
    } else if(image->channels == 4){
        for(int i=0; i<image->height*image->width; i++){
            data_cma[4*i+0] = image->data[4*i+0];
            data_cma[4*i+1] = image->data[4*i+1];
            data_cma[4*i+2] = image->data[4*i+2];
            data_cma[4*i+3] = 0;
        }
    } else{
        _W("The number of channels is not supported");
    }

    free(image->data);
    image->data = data_cma;
    return 0;
}


void image_deinit(image_t *image){
    cma_free(image->data);
}

void print_help(const char *exec){
    _I("USAGE:");
    _I("\n%s <image name>", exec);
}

int main(int argc, char *argv[])
{
    image_t image;
    unsigned time_vga;

    if(argc < 2){
        print_help(argv[0]);
        return 0;
    }

    _I("Initializing DMAs API");
    msgdma_vga    = msgdma_init("/dev/msgdma0");
    enable_global_interrupt_mask(msgdma_vga);

    _I("Initializing CMA API");
    cma_init();

    _I("Loading image...");
    if(image_load(&image, argv[1]) == -1){
        _E("Failed to load image");
        return -1;
    }

    _I("Sending image...");
    timer_us_start();
    fpga_vga(&image);
    time_vga = timer_us_stop();
    _I("Time elapsed == %d us", time_vga);
    

    _I("Deinitializing images...");
    image_deinit(&image);

    _I("Deinitializing APIs...");
    cma_release();
    msgdma_release(msgdma_vga);

	return 0;
}
