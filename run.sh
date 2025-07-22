#!/bin/bash

# Путь к каталогу с фотографиями
SOURCE_DIR="DCIM"
DEST_DIR="GOLDEN_PHOTO"

# Создаем целевой каталог, если он не существует
mkdir -p "$DEST_DIR"

shopt -s nullglob

# Ищем дубликаты .MOV и удаляем их, если соответствующий оригинал существует в том же каталоге
find "${SOURCE_DIR}" -type f -iname "*.MOV" | while read -r mov; do
    if [[ -f "$mov" ]]; then
        base_name=$(basename "$mov" .MOV)
        dir_name=$(dirname "$mov")
        
        # Проверяем наличие соответствующего .HEIC, .JPG или .PNG в том же подкаталоге
        if [[ -f "$dir_name/$base_name.HEIC" ]]; then
            #  -f "$dir_name/$base_name.JPG"  || \
            #  -f "$dir_name/$base_name.PNG" ]]; then
            echo "Удаляем дубликат: $mov"
            rm "$mov"
        fi
    fi
done

# Перебираем все видео в каталоге и подкаталогах
find "$SOURCE_DIR" -type f -iname "*.MOV" | while read -r mov; do
    if [[ -f "$mov" ]]; then
        # Получаем дату создания файла с помощью mediainfo
        creation_date=$(mediainfo ${mov} | grep "Tagged date" | head -1 | awk '{ print $5 }')
        creation_time=$(mediainfo ${mov} | grep "Tagged date" | head -1 | awk '{ print $6 }')
        
        # Проверяем, была ли получена дата создания
        if [[ -n "$creation_date" ]]; then
            # Преобразуем дату в формат YYYY-MM-DD
            year=$(date -d "$creation_date" +"%Y")
            
            # Создаем целевой каталог для года, если он не существует
            YEAR_DIR="$DEST_DIR/$year/VIDEO"
            mkdir -p "$YEAR_DIR"
            
            # Переименовываем файл в формат YYYY-MM-DD_ИмяФайла
            new_mov_name="${creation_date}_$(basename "${mov}")"
            new_mov_path="${YEAR_DIR}/$new_mov_name"
                        
            # Перемещаем видеофайл в целевой каталог
            mv "$mov" "$new_mov_path"
            touch -d "${creation_date} ${creation_time}" ${new_mov_path}
            echo "Перемещен: $mov -> $new_mov_path"
        else
            # Если дата не найдена, сохраняем файл без переименования в отдельный каталог
            NO_DATE_DIR="$DEST_DIR/NO_DATE"
            mkdir -p "$NO_DATE_DIR"
            
            # Генерируем уникальное имя для файла
            base_name=$(basename "$mov")
            unique_name="$base_name"
            counter=1
            
            while [[ -f "$NO_DATE_DIR/$unique_name" ]]; do
                unique_name="${base_name%.*}_$counter.${base_name##*.}"
                ((counter++))
            done
            
            mv "$mov" "$NO_DATE_DIR/$unique_name"
            echo "Сохранён без даты: $mov -> $NO_DATE_DIR/$unique_name"
        fi
    fi
done

for file in $(find ${SOURCE_DIR} -name "*.HEIC"); do
    # Проверяем, существует ли файл
    if [[ -f "$file" ]]; then
        # Получаем имя файла без расширения
        filename="${file%.HEIC}"

        # Конвертация в JPG
        heif-convert "$file" "${filename}.JPG"

        # Проверяем успешность конвертации
        if [[ $? -eq 0 ]]; then
            echo "Конвертировано: $file -> ${filename}.JPG"
            # Удаляем исходный HEIC файл
            rm "$file"

            # Удаляем вспомогательные изображения
            for aux_file in "${filename}"-*; do
                if [[ -f "$aux_file" ]]; then
                    echo "Удаляем вспомогательное изображение: $aux_file"
                    rm "$aux_file"
                fi
            done
        else
            echo "Ошибка при конвертации $file"
        fi
    else
        echo "Нет файлов .HEIC для конвертации."
    fi
done

# Перебираем все изображения в каталоге и подкаталогах
#find "${SOURCE_DIR}" -type f \( -iname "*.heic" -o -iname "*.JPG" -o -iname "*.png" \) | while read -r img; do
find "${SOURCE_DIR}" -type f \( -iname "*.JPG" -o -iname "*.PNG" \) | while read -r img; do
    if [[ -f "${img}" ]]; then
        # Получаем дату создания файла
        creation_date=$(exiv2 -pa "${img}" | grep "Exif.Photo.DateTimeOriginal" | awk '{print $4}' | tr ':' '-')
        creation_time=$(exiv2 -pa "${img}" | grep "Exif.Photo.DateTimeOriginal" | awk '{print $5}')
        # Проверяем, была ли получена дата создания
        if [[ -n "${creation_date}" ]]; then
            # Преобразуем дату в формат YYYY
            year=$(date -d "${creation_date}" +"%Y")
            
            # Создаем целевой каталог для года, если он не существует
            YEAR_DIR="${DEST_DIR}/${year}"
            mkdir -p "${YEAR_DIR}"
            
            # Переименовываем файл в формат YYYY-MM-DD_ИмяФайла
            new_img_name="${creation_date}_$(basename "${img}")"
            new_img_path="${YEAR_DIR}/$new_img_name"
            
            # Перемещаем файл в целевой каталог
            mv "${img}" "${new_img_path}"
            touch -d "${creation_date} ${creation_time}" ${new_img_path}
            echo "Перемещен: ${new_img_path}"
        else
            # Если дата не найдена, сохраняем файл без переименования в отдельный каталог
            NO_DATE_DIR="$DEST_DIR/NO_DATE"
            mkdir -p "$NO_DATE_DIR"
            
            # Генерируем уникальное имя для файла
            base_name=$(basename "$img")
            unique_name="$base_name"
            counter=1
            
            while [[ -f "$NO_DATE_DIR/$unique_name" ]]; do
                unique_name="${base_name%.*}_$counter.${base_name##*.}"
                ((counter++))
            done
            
            mv "$img" "$NO_DATE_DIR/$unique_name"
            echo "Сохранён без даты: $img -> $NO_DATE_DIR/$unique_name"
        fi
    fi
done

echo "Скрипт завершён."
