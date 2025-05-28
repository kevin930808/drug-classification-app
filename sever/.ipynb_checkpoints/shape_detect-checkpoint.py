from ultralytics import YOLO
import os
import cv2
import numpy as np

def load_model(model_path):
    """加載YOLO模型"""
    return YOLO(model_path)

def process_image(image, model):
    """
    處理圖片並返回檢測結果（只返回标签）
    image可以是图片路径或numpy数组
    """
    try:
        # 如果輸入是圖片路徑，讀取圖片
        if isinstance(image, str):
            image = cv2.imread(image)
            if image is None:
                raise ValueError(f"無法讀取圖片")
        
        # 確保圖片是BGR格式
        if len(image.shape) == 2:  # 如果是灰度圖
            image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
        elif image.shape[-1] == 4:  # 如果是RGBA
            image = image[..., :3]
        
        # 執行推理
        results = model.predict(image)
        conf_threshold = 0.5
        # 處理檢測結果，只返回类别标签
        labels = []
        for result in results:
            boxes = result.boxes
            original_img = result.orig_img
            if len(boxes) > 0:
                for box in boxes:
                    if (box.conf.item() > conf_threshold):
                        cls = int(box.cls.item())
                        class_name = result.names[cls]
                        labels.append(class_name)
                        max_conf_idx = np.argmax([box.conf.item() for box in boxes])
                        max_conf_box = boxes[max_conf_idx]
                        x1, y1, x2, y2 = map(int, max_conf_box.xyxy[0])
                        # 裁剪並調整大小
                        crop_img = original_img[y1:y2, x1:x2]
                        # padded_crop_img = resize_with_padding(crop_img)
                        return labels, crop_img
        return [], image  # 如果沒有檢測到任何東西，返回空列表和原始圖片
    except Exception as e:
        print(f"處理圖片時出錯: {str(e)}")
        return [], image

def print_detection_results(image_file, labels):
    """打印檢測結果"""
    print(f"\n正在處理圖片: {image_file}")
    if labels:
        print("檢測到的形状：")
        for label in labels:
            print(f"- {label}")
    else:
        print("未檢測到任何形状！")

def main(image_path):
    """主函數"""
    # 設定參數
    model_path = "model_v4.pt"
    
    # 加載模型
    model = load_model(model_path)
    
    # 檢查是否為檔案或目錄
    if os.path.isfile(image_path):
        # 處理單個檔案
        labels = process_image(image_path, model)
        print_detection_results(os.path.basename(image_path), labels)
    elif os.path.isdir(image_path):
        # 處理目錄中的所有圖片
        image_files = get_image_files(image_path)
        for image_file in image_files:
            full_path = os.path.join(image_path, image_file)
            labels = process_image(full_path, model)
            print_detection_results(image_file, labels)
    else:
        print(f"錯誤：{image_path} 不是有效的檔案或目錄")

def resize_with_padding(image, target_size=(500, 500)):
    h, w = image.shape[:2]
    target_w, target_h = target_size
    scale = min(target_w / w, target_h / h)
    new_w = int(w * scale)
    new_h = int(h * scale)
    resized_img = cv2.resize(image, (new_w, new_h))
    padded_img = np.zeros((target_h, target_w, 3), dtype=np.uint8)
    top = (target_h - new_h) // 2
    left = (target_w - new_w) // 2
    padded_img[top:top + new_h, left:left + new_w] = resized_img
    return padded_img

if __name__ == "__main__":
    print("請通過 API 調用此模組")