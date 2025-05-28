from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import io
import cv2
import numpy as np
import os
import shape_detect
import letter_detect
import color_detect
import uvicorn
import sys
import pandas as pd
import image_enhancement

app = FastAPI(title="藥丸特徵檢測API")

# 添加 CORS 中間件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 預加載模型
shape_model = shape_detect.load_model("model_v4.pt")
letter_model = letter_detect.load_model("model_刻字v3.pt")
color_model = color_detect.load_model("model_color_v5.pt")

def get_best_shape(shape_result):
    """
    從形狀檢測結果中獲取形狀名稱
    shape_result格式: 'pill_round' 或類似的字符串，或空列表表示無檢測結果
    """
    if not shape_result or (isinstance(shape_result, list) and len(shape_result) == 0):
        return "未檢測到形狀", 0.0
    
    # 如果是列表且有內容，取第一個元素；否則直接使用結果
    result = shape_result[0] if isinstance(shape_result, list) and len(shape_result) > 0 else shape_result
    return result, 1.0

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
        img_array = image
        
        # 使用預加載的模型進行檢測
        shape_and_crop = shape_detect.process_image(img_array, shape_model)
        shape_result = shape_and_crop[0]  # 形狀字符串或列表
        crop = shape_and_crop[1]
        
        # 獲取形狀結果
        shape_name, shape_confidence = get_best_shape(shape_result)
        
        letter_labels = letter_detect.process_image(crop, letter_model)  # 刻字列表
        crop=image_enhancement.enhance_image(crop)
        color_labels = color_detect.process_image(crop, color_model)  # 顏色列表，每個元素是(顏色, 置信度)元組
        
        print(f"檢測到的形狀: {shape_name} (置信度: {shape_confidence})")
        print(f"檢測到的刻字: {letter_labels}")
        print(f"檢測到的顏色: {color_labels}")
        
        # 從數據庫中查詢藥物信息
        try:
            data_base = pd.read_csv("data base/test data base.csv").values
            score_array = np.zeros(data_base.shape[0])
            
            # 計算每個藥物的匹配分數
            for i, drug in enumerate(data_base):
                # 獲取檢測結果
                detected_shape = shape_name if shape_name != "未檢測到形狀" else ""
                detected_letters = letter_labels if letter_labels else []
                detected_color = color_labels[0][0] if color_labels else ""  # 只取顏色名稱，不要置信度
                
                # 處理數據庫中的值
                drug_shape = str(drug[1]).strip().lower()
                drug_color = str(drug[2]).strip().lower()
                drug_letter = str(drug[3]).strip().lower()
                
                # 將數據庫中的刻字字符串轉換為集合
                drug_letters_set = set(letter.strip() for letter in drug_letter.split(','))
                detected_letters_set = set(letter.lower() for letter in detected_letters)
                
                # 初始化分數詳情
                score_details = {
                    "shape_score": 0,
                    "color_score": 0,
                    "letter_score": 0,
                    "total_score": 0,
                    "matches": {
                        "shape": False,
                        "color": False,
                        "letter": False
                    }
                }
                
                print(f"\n比對藥物: {drug[0]}")
                print(f"檢測到的特徵:")
                print(f"- 形狀: {detected_shape} (數據庫: {drug_shape})")
                print(f"- 顏色: {detected_color} (數據庫: {drug_color})")
                print(f"- 刻字: {detected_letters} (數據庫: {drug_letter})")
                print(f"- 刻字集合比對: {detected_letters_set} vs {drug_letters_set}")
                
                # 形狀匹配（0.4分）- 考慮置信度
                if detected_shape and detected_shape.lower() == drug_shape:
                    score_details["shape_score"] = 0.4 * shape_confidence
                    score_details["matches"]["shape"] = True
                    score_array[i] += score_details["shape_score"]
                    print(f"✓ 形狀匹配成功: +{score_details['shape_score']:.2f}分")
                else:
                    score_array[i] -= 1
                    print("✗ 形狀不匹配")
                
                # 顏色匹配（0.3分）
                if detected_color and detected_color.lower() in drug_color:
                    score_details["color_score"] = 0.3
                    score_details["matches"]["color"] = True
                    score_array[i] += score_details["color_score"]
                    print(f"✓ 顏色匹配成功: +{score_details['color_score']:.2f}分")
                else:
                    score_details["color_score"] = -0.2
                    score_array[i] += score_details["color_score"]
                    print(f"✗ 顏色不匹配: {score_details['color_score']:.2f}分")
                
                # 刻字匹配（0.3分）- 根據正確匹配的數量計算分數
                if detected_letters and drug_letters_set:
                    # 計算正確匹配的數量
                    correct_matches = len(drug_letters_set.intersection(detected_letters_set))
                    total_expected = len(drug_letters_set)
                    
                    # 計算分數：正確匹配數/總數 * 0.3
                    if total_expected > 0:
                        score_details["letter_score"] = (correct_matches / total_expected) * 0.3
                        score_details["matches"]["letter"] = True
                        score_array[i] += score_details["letter_score"]
                        print(f"✓ 刻字部分匹配成功: {correct_matches}/{total_expected} 正確")
                        print(f"  得分: +{score_details['letter_score']:.2f}分")
                    else:
                        print("✗ 數據庫中沒有刻字記錄")
                else:
                    print("✗ 刻字不匹配")
                    if detected_letters:
                        print(f"  檢測到的刻字: {detected_letters_set}")
                        print(f"  數據庫中的刻字: {drug_letters_set}")
                        print(f"  差異: {detected_letters_set.symmetric_difference(drug_letters_set)}")
                
                score_details["total_score"] = score_array[i]
                print(f"總分: {score_details['total_score']:.2f}\n")
                print("-" * 50)
            
            # 找出最佳匹配
            max_index = np.argmax(score_array)
            max_score = score_array[max_index]
            
            if max_score <= 0:
                name = "未知藥物"
                print("\n未找到匹配藥物")
            else:
                name = data_base[max_index][0]
                print(f"\n找到最佳匹配藥物: {name}")
                print(f"最終得分: {max_score:.2f}")
            
            # 返回檢測結果
            return JSONResponse(
                status_code=200,
                content={
                    "name": name,
                    "shape": shape_name,
                    "shape_confidence": float(shape_confidence),
                    "letter": letter_labels if letter_labels else [],
                    "color": color_labels[0][0] if color_labels else "",
                    "confidence": float(max_score)
                }
            )
            
        except Exception as db_error:
            print(f"數據庫查詢錯誤: {str(db_error)}")
            print(f"錯誤詳情: ", db_error.__class__.__name__)
            import traceback
            print(traceback.format_exc())
            return JSONResponse(
                status_code=200,
                content={
                    "name": "數據庫查詢錯誤",
                    "shape": shape_name,
                    "shape_confidence": float(shape_confidence),
                    "letter": letter_labels if letter_labels else [],
                    "color": color_labels[0][0] if color_labels else ""
                }
            )
        
    except Exception as e:
        print(f"處理圖片時出錯: {str(e)}")
        print("錯誤堆疊:")
        import traceback
        print(traceback.format_exc())
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
            "name": "藥物名稱",
            "shape": "藥丸形狀",
            "shape_confidence": "形狀檢測置信度",
            "letter": "檢測到的所有刻字",
            "color": "藥丸顏色",
            "confidence": "整體匹配置信度（0-1）"
        }
    }

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("api:app", host="0.0.0.0", port=port, reload=False) 