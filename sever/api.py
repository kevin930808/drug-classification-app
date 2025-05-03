from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import io
import cv2
import numpy as np
import os
import shape_detect
import letter_detect
import color_detect
import uvicorn
import sys

app = FastAPI(title="藥丸特徵檢測API")
@app.post("/detect/")
async def detect_features(file: UploadFile = File(...)):
    """
    上傳圖片並檢測其特徵（形狀、刻字、顏色）
    """ 
    # 檢查檔案類型
    if not file.content_type.startswith("image/"):
        return JSONResponse(
            status_code=400,
            content={"detail": "只接受圖片檔案"}
        )
    
    try:
        # 讀取圖片內容到記憶體
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED)
        #img_array = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        img_array=image
        shape_and_crop = shape_detect.process_image(img_array, shape_detect.load_model("model_v4.pt"))
        shape=shape_and_crop[0]
        crop=shape_and_crop[1]
        letter_labels = letter_detect.process_image(img_array, letter_detect.load_model("model_刻字v3.pt"))
        color_labels = color_detect.process_image(crop, color_detect.load_model("model_color_v4.pt"))
        # 返回檢測結果
        return JSONResponse(
            status_code=200,
            content={
                "shape": shape,
                "letter": letter_labels,
                "color": color_labels
            }
        )
        
    except Exception as e:
        print(f"處理圖片時出錯: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"detail": f"處理圖片時出錯: {str(e)}"}
        )
    finally:
        await file.close()

@app.get("/")
async def root():
    """API 根路徑"""
    return {
        "message": "藥丸特徵檢測API",
        "usage": "請使用 POST /detect/ 端點上傳圖片",
        "supported_formats": ["image/jpeg", "image/png"],
        "response_format": {
            "shape": "藥丸形狀列表",
            "letter": "檢測到的刻字列表",
            "color": "藥丸顏色列表"
        }
    }

if __name__ == "__main__":
    # 載入模型
    # 啟動服務器
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=False) 