/* watermark_extended.c
 *
 * Implementation of extended watermark functionality
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "watermark_extended.h"

watermark_extended_t* watermark_create() {
    watermark_extended_t *wm = malloc(sizeof(watermark_extended_t));
    if (!wm) return NULL;
    
    wm->type = WATERMARK_TYPE_NONE;
    wm->image_path = NULL;
    wm->image_width = 0;
    wm->image_height = 0;
    wm->text = NULL;
    wm->font_name = strdup("Arial");
    wm->font_size = 24;
    wm->text_color = 0xFFFFFF;
    wm->text_bold = 0;
    wm->text_italic = 0;
    wm->outline_color = 0x000000;
    wm->outline_width = 2;
    wm->position_preset = WATERMARK_POSITION_BOTTOM_RIGHT;
    wm->position_x = 0;
    wm->position_y = 0;
    wm->use_percentage = 1;
    wm->opacity = 70;
    wm->rotation = 0;
    wm->margin_x = 10;
    wm->margin_y = 10;
    
    return wm;
}

void watermark_free(watermark_extended_t *wm) {
    if (!wm) return;
    free(wm->image_path);
    free(wm->text);
    free(wm->font_name);
    free(wm);
}

void watermark_set_image(watermark_extended_t *wm, const char *path) {
    if (!wm || !path) return;
    
    free(wm->image_path);
    wm->image_path = strdup(path);
    wm->type = WATERMARK_TYPE_IMAGE;
}

void watermark_set_text(watermark_extended_t *wm, const char *text) {
    if (!wm || !text) return;
    
    free(wm->text);
    wm->text = strdup(text);
    wm->type = WATERMARK_TYPE_TEXT;
}

void watermark_set_position_xy(watermark_extended_t *wm, int x, int y, int use_percentage) {
    if (!wm) return;
    
    wm->position_preset = WATERMARK_POSITION_CUSTOM;
    wm->position_x = x;
    wm->position_y = y;
    wm->use_percentage = use_percentage;
}

void watermark_set_position_preset(watermark_extended_t *wm, watermark_position_preset_t preset) {
    if (!wm) return;
    wm->position_preset = preset;
}

static void calculate_position_from_preset(watermark_extended_t *wm, int video_width, int video_height,
                                          int *out_x, int *out_y, int watermark_width, int watermark_height) {
    switch (wm->position_preset) {
        case WATERMARK_POSITION_TOP_LEFT:
            *out_x = wm->margin_x;
            *out_y = wm->margin_y;
            break;
        case WATERMARK_POSITION_TOP_CENTER:
            *out_x = (video_width - watermark_width) / 2;
            *out_y = wm->margin_y;
            break;
        case WATERMARK_POSITION_TOP_RIGHT:
            *out_x = video_width - watermark_width - wm->margin_x;
            *out_y = wm->margin_y;
            break;
        case WATERMARK_POSITION_MIDDLE_LEFT:
            *out_x = wm->margin_x;
            *out_y = (video_height - watermark_height) / 2;
            break;
        case WATERMARK_POSITION_MIDDLE_CENTER:
            *out_x = (video_width - watermark_width) / 2;
            *out_y = (video_height - watermark_height) / 2;
            break;
        case WATERMARK_POSITION_MIDDLE_RIGHT:
            *out_x = video_width - watermark_width - wm->margin_x;
            *out_y = (video_height - watermark_height) / 2;
            break;
        case WATERMARK_POSITION_BOTTOM_LEFT:
            *out_x = wm->margin_x;
            *out_y = video_height - watermark_height - wm->margin_y;
            break;
        case WATERMARK_POSITION_BOTTOM_CENTER:
            *out_x = (video_width - watermark_width) / 2;
            *out_y = video_height - watermark_height - wm->margin_y;
            break;
        case WATERMARK_POSITION_BOTTOM_RIGHT:
            *out_x = video_width - watermark_width - wm->margin_x;
            *out_y = video_height - watermark_height - wm->margin_y;
            break;
        case WATERMARK_POSITION_CUSTOM:
        default:
            if (wm->use_percentage) {
                *out_x = (video_width * wm->position_x) / 100;
                *out_y = (video_height * wm->position_y) / 100;
            } else {
                *out_x = wm->position_x;
                *out_y = wm->position_y;
            }
            break;
    }
}

char* watermark_to_ffmpeg_filter(watermark_extended_t *wm, int video_width, int video_height) {
    if (!wm || wm->type == WATERMARK_TYPE_NONE) return NULL;
    
    char *filter = malloc(2048);
    if (!filter) return NULL;
    
    float alpha = wm->opacity / 100.0f;
    
    if (wm->type == WATERMARK_TYPE_IMAGE) {
        if (!wm->image_path) {
            free(filter);
            return NULL;
        }
        
        int x, y;
        int img_width = wm->image_width > 0 ? wm->image_width : 100;
        int img_height = wm->image_height > 0 ? wm->image_height : 100;
        
        calculate_position_from_preset(wm, video_width, video_height, &x, &y, img_width, img_height);
        
        // FFmpeg overlay filter for image watermark
        snprintf(filter, 2048,
                 "movie=%s,scale=%d:%d,format=rgba,colorchannelmixer=aa=%.2f[wm];[in][wm]overlay=%d:%d[out]",
                 wm->image_path, img_width, img_height, alpha, x, y);
        
    } else if (wm->type == WATERMARK_TYPE_TEXT) {
        if (!wm->text) {
            free(filter);
            return NULL;
        }
        
        int x, y;
        // Estimate text dimensions (rough approximation)
        int text_width = strlen(wm->text) * wm->font_size * 0.6;
        int text_height = wm->font_size * 1.2;
        
        calculate_position_from_preset(wm, video_width, video_height, &x, &y, text_width, text_height);
        
        // FFmpeg drawtext filter for text watermark
        const char *weight = wm->text_bold ? "bold" : "normal";
        const char *style = wm->text_italic ? "italic" : "normal";
        
        snprintf(filter, 2048,
                 "drawtext=text='%s':fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf:"
                 "fontsize=%d:fontcolor=0x%06X@%.2f:x=%d:y=%d:"
                 "borderw=%d:bordercolor=0x%06X",
                 wm->text, wm->text_bold ? "-Bold" : "",
                 wm->font_size, wm->text_color, alpha, x, y,
                 wm->outline_width, wm->outline_color);
    }
    
    return filter;
}
