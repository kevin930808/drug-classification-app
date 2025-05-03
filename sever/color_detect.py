from ultralytics import YOLO
import os
import numpy as np
import cv2

def load_model(model_path):
    """加載YOLO模型"""
    return YOLO(model_path)

def process_image(image, model):
    """
    處理圖片並返回檢測結果（返回標籤和置信度）
    image可以是圖片路徑或numpy數組
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
        conf_threshold = 0.1
        
        # 處理檢測結果，返回標籤和置信度
        detections = []
        for result in results:
            boxes = result.boxes
            if len(boxes) > 0:
                for box in boxes:
                    if box.conf.item() > conf_threshold:
                        cls = int(box.cls.item())
                        class_name = result.names[cls]
                        confidence = box.conf.item()
                        detections.append((class_name, confidence))
                return detections
        return []
    except Exception as e:
        print(f"處理圖片時出錯: {str(e)}")
        return []

def print_detection_results(image_file, detections):
    """打印檢測結果"""
    print(f"\n正在處理圖片: {image_file}")
    if detections:
        print("檢測到的顏色：")
        for label, confidence in detections:
            print(f"- {label} (置信度: {confidence:.2f})")
    else:
        print("未檢測到任何顏色！")

def main(image_path):
    """主函數"""
    # 設定參數
    model_path="model_color_v3.pt"
    # 加載模型
    model = load_model(model_path)
    
    # 檢查是否為檔案或目錄
    if os.path.isfile(image_path):
        # 處理單個檔案
        detections = process_image(image_path, model)
        print_detection_results(os.path.basename(image_path), detections)
    elif os.path.isdir(image_path):
        # 處理目錄中的所有圖片
        image_files = [f for f in os.listdir(image_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        for image_file in image_files:
            full_path = os.path.join(image_path, image_file)
            detections = process_image(full_path, model)
            print_detection_results(image_file, detections)
    else:
        print(f"錯誤：{image_path} 不是有效的檔案或目錄")

if __name__ == "__main__":
    print("請通過 API 調用此模組")