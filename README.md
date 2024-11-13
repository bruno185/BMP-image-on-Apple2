* * * * * * * * * * * * * * * * * * * * * * * * * * * 
*                                                   *
*   Diplay a BMP image using Graphics Primitives    *      
*                                                   *  
* * * * * * * * * * * * * * * * * * * * * * * * * * *  
*
* BMP is loaded by this program, and tests are performed :
        * BMP image must have 1 bit per pixel
        * Dimension must not exceed 280 x 192
        * Every bit (= pixel) in BMP file is doubled horizontally 
* to respect image aspect ratio (more or less)
* The image is drawn line by line, using PaintBits function of Graphics Primitives package
