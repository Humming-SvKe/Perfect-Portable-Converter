/* example_watermark_usage.c
 *
 * Príklady použitia Watermark API
 */

#include <stdio.h>
#include "watermark_extended.h"

void example_image_watermark() {
    printf("=== Image Watermark Example ===\n");
    
    watermark_extended_t *wm = watermark_create();
    
    // Nastavenie obrázka
    watermark_set_image(wm, "logo.png");
    wm->image_width = 150;
    wm->image_height = 150;
    
    // Pozícia: Top Right corner
    watermark_set_position_preset(wm, WATERMARK_POSITION_TOP_RIGHT);
    wm->margin_x = 20;
    wm->margin_y = 20;
    
    // Priehľadnosť 80%
    wm->opacity = 80;
    
    // Generovanie FFmpeg filtra
    char *filter = watermark_to_ffmpeg_filter(wm, 1920, 1080);
    if (filter) {
        printf("FFmpeg Filter:\n%s\n\n", filter);
        free(filter);
    }
    
    watermark_free(wm);
}

void example_text_watermark() {
    printf("=== Text Watermark Example ===\n");
    
    watermark_extended_t *wm = watermark_create();
    
    // Nastavenie textu
    watermark_set_text(wm, "© 2025 My Company");
    wm->font_name = strdup("Arial");
    wm->font_size = 32;
    wm->text_color = 0xFFFFFF;  // White
    wm->text_bold = 1;
    wm->text_italic = 0;
    
    // Outline pre lepšiu čitateľnosť
    wm->outline_width = 3;
    wm->outline_color = 0x000000;  // Black
    
    // Pozícia: Bottom Center
    watermark_set_position_preset(wm, WATERMARK_POSITION_BOTTOM_CENTER);
    wm->margin_y = 30;
    
    // Priehľadnosť 90%
    wm->opacity = 90;
    
    char *filter = watermark_to_ffmpeg_filter(wm, 1920, 1080);
    if (filter) {
        printf("FFmpeg Filter:\n%s\n\n", filter);
        free(filter);
    }
    
    watermark_free(wm);
}

void example_custom_position() {
    printf("=== Custom Position Example ===\n");
    
    watermark_extended_t *wm = watermark_create();
    
    // Text watermark
    watermark_set_text(wm, "DRAFT");
    wm->font_size = 120;
    wm->text_color = 0xFF0000;  // Red
    wm->text_bold = 1;
    
    // Custom pozícia v percentách (stred obrazovky)
    watermark_set_position_xy(wm, 50, 50, 1);  // 50% x, 50% y, percentá
    
    // Semi-transparent
    wm->opacity = 30;
    
    // Rotácia 45°
    wm->rotation = 45;
    
    char *filter = watermark_to_ffmpeg_filter(wm, 1920, 1080);
    if (filter) {
        printf("FFmpeg Filter:\n%s\n\n", filter);
        free(filter);
    }
    
    watermark_free(wm);
}

void example_drag_drop_coordinates() {
    printf("=== Drag & Drop Coordinates Example ===\n");
    
    watermark_extended_t *wm = watermark_create();
    
    // Simulácia hodnôt z drag & drop canvas
    // Používateľ presunul watermark na pozíciu 320, 180
    watermark_set_image(wm, "watermark.png");
    wm->image_width = 100;
    wm->image_height = 50;
    
    // Presné pixelové súradnice z drag & drop
    watermark_set_position_xy(wm, 320, 180, 0);  // Pixely, nie percentá
    
    wm->opacity = 70;
    
    char *filter = watermark_to_ffmpeg_filter(wm, 1920, 1080);
    if (filter) {
        printf("FFmpeg Filter:\n%s\n\n", filter);
        free(filter);
    }
    
    watermark_free(wm);
}

void example_multiple_watermarks() {
    printf("=== Multiple Watermarks Workflow ===\n");
    
    // Logo v pravom hornom rohu
    watermark_extended_t *logo = watermark_create();
    watermark_set_image(logo, "logo.png");
    logo->image_width = 80;
    logo->image_height = 80;
    watermark_set_position_preset(logo, WATERMARK_POSITION_TOP_RIGHT);
    logo->margin_x = 10;
    logo->margin_y = 10;
    logo->opacity = 90;
    
    // Copyright text dole
    watermark_extended_t *copyright = watermark_create();
    watermark_set_text(copyright, "© 2025");
    copyright->font_size = 20;
    copyright->text_color = 0xFFFFFF;
    watermark_set_position_preset(copyright, WATERMARK_POSITION_BOTTOM_RIGHT);
    copyright->margin_x = 15;
    copyright->margin_y = 15;
    copyright->opacity = 80;
    
    // Generovanie filtrov
    char *filter1 = watermark_to_ffmpeg_filter(logo, 1920, 1080);
    char *filter2 = watermark_to_ffmpeg_filter(copyright, 1920, 1080);
    
    if (filter1 && filter2) {
        printf("Logo Filter:\n%s\n\n", filter1);
        printf("Copyright Filter:\n%s\n\n", filter2);
        printf("Combined FFmpeg command:\n");
        printf("ffmpeg -i input.mp4 -vf \"%s,%s\" output.mp4\n\n", filter1, filter2);
        
        free(filter1);
        free(filter2);
    }
    
    watermark_free(logo);
    watermark_free(copyright);
}

int main() {
    printf("HandBrake Extended Watermark Examples\n");
    printf("=====================================\n\n");
    
    example_image_watermark();
    example_text_watermark();
    example_custom_position();
    example_drag_drop_coordinates();
    example_multiple_watermarks();
    
    return 0;
}
