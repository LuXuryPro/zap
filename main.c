#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define BMP_MAGIC 0x424D

typedef struct                       /**** BMP file header structure ****/
{
    unsigned int bfSize;
    /* Size of file */
    unsigned short bfReserved1;
    /* Reserved */
    unsigned short bfReserved2;
    /* ... */
    unsigned int bfOffBits;        /* Offset to bitmap data */
} BITMAPFILEHEADER;

typedef struct                       /**** BMP file info structure ****/
{
    unsigned int biSize;
    /* Size of info header */
    int biWidth;
    /* Width of image */
    int biHeight;
    /* Height of image */
    unsigned short biPlanes;
    /* Number of color planes */
    unsigned short biBitCount;
    /* Number of bits per pixel */
    unsigned int biCompression;
    /* Type of compression to use */
    unsigned int biSizeImage;
    /* Size of image data */
    int biXPelsPerMeter;
    /* X pixels per meter */
    int biYPelsPerMeter;
    /* Y pixels per meter */
    unsigned int biClrUsed;
    /* Number of colors used */
    unsigned int biClrImportant;   /* Number of important colors */
} BITMAPINFOHEADER;

typedef struct {
    unsigned char r, g, b;
} Pixel;
typedef struct {
    int width;
    int height;
    int padding;
    Pixel *data;
} Image;


/*assembler functions*/
void canny(void *src, void *dst, int height, int width);
void thresholding(void * data, int height, int width, char lower, char upper);
void blur_assembly(void * data, void * dst, int height, int width);

void *reduce_colors(Image *source) {
    char *data = malloc((size_t) (source->height * source->width));
    for (int i = 0; i < source->height; i++) {
        for (int j = 0; j < source->padding / 3; j++) {
            Pixel sourcePixel = *(source->data + j + i * source->padding / 3);
            data[i * source->width + j] = ((char) (
                    (float) sourcePixel.r * 0.3 + (float) sourcePixel.g * 0.59 +
                    (float) sourcePixel.b * 0.11) )^ 0x80;
        }
    }
    return data;
}

void * back_colors(unsigned char *data, int height, int width, int padding) {
    char *ret_data = malloc((size_t) (height * padding));
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            unsigned char val = *(data + j + i * width);
            *(ret_data + j * 3 + i * padding) = val;
            *(ret_data + j * 3 + i * padding + 1) = val;
            *(ret_data + j * 3 + i * padding + 2) = val;
        }
    }
    return ret_data;
}

void *roberts_cross(unsigned char *data, int height, int width) {
    unsigned char *ret_data = malloc((size_t) (width * height));
    canny(data, ret_data, height, width);
    return ret_data;
}

void * blur(char * data, int height, int width)
{
    char *ret_data = malloc((size_t) (width * height));
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int sourcePixel = *(data + j + i * width);
            int up = *(data + j + (i + 1)* width);
            int right = *(data + j + 1 + i * width);
            int cross = *(data + j + 1 + (i + 1) * width);
            *(ret_data + j + i * width) = (char)((sourcePixel + up + right + cross)/4);
        }
    }
    return ret_data;
}

int main(int argc, char **argv) {
    if (argc != 3)
        return -1;
    BITMAPFILEHEADER bfh = {0};
    BITMAPINFOHEADER bih = {0};
    FILE *f = fopen(argv[1], "rb");
    if (f == NULL)
        return -1;
    fseek(f, 2, 0); //omijam BM
    fread(&bfh, sizeof(BITMAPFILEHEADER), 1, f);
    fread(&bih, sizeof(BITMAPINFOHEADER), 1, f);
    fseek(f, bfh.bfOffBits, 0);
    int padding = ((24 * bih.biWidth + 31) / 32) * 4;
    void *image_data = malloc(padding * bih.biHeight);
    fread(image_data, bih.biSizeImage, 1, f);
    fclose(f);

    //tu bedzie przetwarzanie
    Image img;
    img.width = bih.biWidth;
    img.height = bih.biHeight;
    img.data = image_data;
    img.padding = padding;
    Image dst;
    dst.height = img.height;
    dst.width = img.width;
    dst.padding = img.padding;
    void *reducedImage = reduce_colors(&img);
    reducedImage = blur(reducedImage, img.height, img.width);
    void *crossed = roberts_cross(reducedImage, img.height, img.width);
    thresholding(crossed, img.height, img.width, 20, 40);
    dst.data = back_colors(crossed, img.height, img.width, padding);


    FILE *z = fopen(argv[2], "w");
    char *magic = "BM";
    fwrite(magic, sizeof(char), 2, z);
    bfh.bfSize = dst.height * padding + 54;
    bfh.bfOffBits = 54;
    fwrite(&bfh, sizeof(BITMAPFILEHEADER), 1, z);
    bih.biSizeImage = dst.height * dst.padding;
    bih.biHeight = dst.height;
    bih.biWidth = dst.width;
    bih.biSize = 40;
    fwrite(&bih, sizeof(BITMAPINFOHEADER), 1, z);
    fwrite(dst.data, bih.biSizeImage, 1, z);
    fclose(z);
    return 0;
}


