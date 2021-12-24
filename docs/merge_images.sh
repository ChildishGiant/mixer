#!/usr/bin/env bash

# Taken from https://github.com/small-tech/watson/blob/main/template/task/take-screenshots
# Copyright ⓒ 2021-present Aral Balkan, Small Technology Foundation.
# Released under GNU GPL version 3.0.

screenshot_dimensions="$(magick light.png -ping -format "%wx%h" info:)"

magick \
\( "light.png" +write mpr:light \) \
\( "dark.png" mpr:light \( -size "${screenshot_dimensions}" xc:white -draw "stroke None fill Black path 'M %[fx:w/1.618],0 L %[fx:w-w/1.618],%[fx:h] L %[fx:w],%[fx:h] L %[fx:w],0 Z'" \) -alpha Off -composite +write mpr:montage \) \
\( mpr:montage \( mpr:light -alpha extract \) -compose CopyOpacity -composite +write "light-and-dark.png" \) \
null:
