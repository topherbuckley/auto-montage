#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR=~/wallpapers

# Temporary directory for storing resized images and the collage
TEMP_DIR=~/temp_wallpapers
mkdir -p "$TEMP_DIR"

# Get the resolution of the primary display using xrandr
PRIMARY_DISPLAY=$(xrandr | grep " connected primary" | cut -d' ' -f1)
SCREEN_RESOLUTION=$(xrandr | grep -A1 "^$PRIMARY_DISPLAY" | tail -n1 | sed -n 's/.* \([0-9]\+x[0-9]\+\) .*/\1/p')
SCREEN_WIDTH=$(echo $SCREEN_RESOLUTION | cut -d'x' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_RESOLUTION | cut -d'x' -f2)

# print the resolution of the primary display
echo "Resolution of the primary display: $SCREEN_RESOLUTION"

# Separate landscape and portrait images
LANDSCAPE_IMAGES=()
PORTRAIT_IMAGES=()

for IMAGE in "$WALLPAPER_DIR"/*; do
    WIDTH=$(identify -format "%w" "$IMAGE")
    HEIGHT=$(identify -format "%h" "$IMAGE")
    if [ "$WIDTH" -gt "$HEIGHT" ]; then
        LANDSCAPE_IMAGES+=("$IMAGE")
    else
        PORTRAIT_IMAGES+=("$IMAGE")
    fi
done

ORIENTATION="landscape"
# Randomly choose to use either landscape or portrait images
if [ $((RANDOM % 2)) -eq 0 ]; then
    IMAGES=("${LANDSCAPE_IMAGES[@]}")
    GRID_COLUMNS=4
    GRID_ROWS=3
    ORIENTATION="landscape"
else
    IMAGES=("${PORTRAIT_IMAGES[@]}")
    GRID_COLUMNS=5
    GRID_ROWS=2
    ORIENTATION="portrait"
fi
#tmp override for debugging
#IMAGES=("${LANDSCAPE_IMAGES[@]}")
#GRID_COLUMNS=4
#GRID_ROWS=3
#ORIENTATION="landscape"

#IMAGES=("${PORTRAIT_IMAGES[@]}")
#GRID_COLUMNS=5
#GRID_ROWS=2
#ORIENTATION="portrait"

echo "Orientation: $ORIENTATION"
echo "Number of rows in the grid: $GRID_ROWS"
echo "Number of columns in the grid: $GRID_COLUMNS"

# Calculate the number of images to use based on the grid size
NUM_IMAGES=$((GRID_COLUMNS * GRID_ROWS))

# Select random images from the chosen orientation
SELECTED_IMAGES=$(printf "%s\n" "${IMAGES[@]}" | shuf -n $NUM_IMAGES)

# Calculate the target size for each image in the grid
TARGET_WIDTH=$((SCREEN_WIDTH / GRID_COLUMNS))
TARGET_HEIGHT=$((SCREEN_HEIGHT / GRID_ROWS))

echo "Target width: $TARGET_WIDTH"
echo "Target height: $TARGET_HEIGHT"

# Resize images to fit within the target size while maintaining aspect ratio
RESIZED_IMAGES=()
for IMAGE in $SELECTED_IMAGES; do
    BASENAME=$(basename "$IMAGE")
    RESIZED_IMAGE="$TEMP_DIR/resized_$BASENAME"
    convert "$IMAGE" -resize "${TARGET_WIDTH}x${TARGET_HEIGHT}" -background white -gravity center -extent ${TARGET_WIDTH}x${TARGET_HEIGHT} "$RESIZED_IMAGE"
    RESIZED_IMAGES+=("$RESIZED_IMAGE")
done

# Create a collage of the resized images
COLLAGE="$TEMP_DIR/collage.png"
montage "${RESIZED_IMAGES[@]}" -tile ${GRID_COLUMNS}x${GRID_ROWS} -geometry +0+0 "$COLLAGE"

echo "montage made with ${GRID_ROWS}x${GRID_COLUMNS} grid"

# Ensure the collage is exactly the screen resolution
convert "$COLLAGE" -resize ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -gravity center -background black -extent ${SCREEN_WIDTH}x${SCREEN_HEIGHT} "$COLLAGE"

# Set the collage as the desktop background
gsettings set org.gnome.desktop.background picture-uri "file://$COLLAGE"

# Clean up temporary resized images
rm "${RESIZED_IMAGES[@]}"
