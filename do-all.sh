#!/bin/bash

# REQUIREMENTS:
# python srt module: install with `pip3 install srt`
# my custom fork of macOCR: https://github.com/glowinthedark/macOCR
#
# USAGE:
# ./do-all.sh video.mp4

read -p "Generate cropped video $1_video-cropped.mp4? (Y/N).." answer
case ${answer:0:1} in
    y|Y )
        ################### TODO: adjust crop area for input video #########################
        ffmpeg -i "$1" -filter:v "crop=1738:115:100:965" -c:a copy "$1_video-cropped.mp4"
    ;;
    * )
        echo Skipping...
    ;;
esac

# STEP 2: extract key frames to png images with detection threshold

# EVERY 0.5 seconds the counter represents seconds * 2
read -p "Generate snapshots (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
        mkdir -p "$1_img"
        ffmpeg -i "$1_video-cropped.mp4" -start_number 1 -vf "fps=4" -q:v 2 "$1_img/snap_%04d.png"
# PREV        ffmpeg -i "$1_video-cropped.mp4" -vf "fps=4" -q:v 2 "$1_img/snap_%d.png"
    ;;
    * )
        echo Skipping...
    ;;
esac

read -p "Start OCR (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
        do-ocr.py "$1_img" "$1_results.json"
    ;;
    * )
        echo Skipping...
    ;;
esac


read -p "Generate SRT (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
        gensrt.py "$1_results.json" "$1.ocr.srt"
    ;;
    * )
        echo Skipping...
    ;;
esac

read -p "SRT normalize and deduplicate inplace (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
      srt-normalise -i "$1.ocr.srt" --inplace --debug
      srt-deduplicate -t 10000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 10000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 10000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 10000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 10000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 10000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 40000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 50000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 60000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 70000 --debug -i "$1.ocr.srt" --inplace
      srt-deduplicate -t 80000 --debug -i "$1.ocr.srt" --inplace
    ;;
    * )
        echo Skipping...
    ;;
esac

read -p "Generate pinyin SRT (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
        srt_subs_zh2pinyin.py "$1.ocr.srt" --force-normalize-input-to-simplified -t -o "$1.ocr.pinyin.srt"
    ;;
    * )
        echo Skipping...
    ;;
esac

read -p "Deepl translate zh:en $1.ocr.srt (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
        python3 deepl.py zh:en "$1.ocr.srt"
    ;;
    * )
        echo Skipping...
    ;;
esac


read -p "SRT merge (y/n)?.." answer
case ${answer:0:1} in
    y|Y )
        srt_merge.py "$1.ocr.pinyin.srt" "$1.ocr.en.srt"
    ;;
    * )
        echo Skipping...
    ;;
esac

exit 0
