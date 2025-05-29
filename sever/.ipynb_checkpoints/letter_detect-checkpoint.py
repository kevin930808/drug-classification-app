from ultralytics import YOLO
import os
import numpy as np
import cv2

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
        conf_threshold = 0.5  # 設置置信度閾值
        
        # 處理檢測結果，只返回类别标签
        labels = []
        for result in results:
            boxes = result.boxes
            if len(boxes) > 0:
                for box in boxes:
                    if box.conf.item() > conf_threshold:  # 只添加高於閾值的檢測結果
                        cls = int(box.cls.item())
                        class_name = result.names[cls]
                        labels.append(class_name)
        return labels
    except Exception as e:
        print(f"處理圖片時出錯: {str(e)}")
        return []

if __name__ == "__main__":
    print("請通過 API 調用此模組")