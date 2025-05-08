import cv2
import numpy as np

def enhance_image(img):
    """
    增强图像颜色对比度并减少噪点
    :param img: 输入的numpy数组图像 (BGR格式)
    :return: 处理后的图像 (numpy数组)
    """
    if not isinstance(img, np.ndarray):
        raise ValueError("输入必须是numpy数组")
    
    # 1. 中值滤波减少噪点
    denoised = cv2.medianBlur(img, 5)
    
    # 2. 转换到HSV颜色空间进行颜色增强
    hsv = cv2.cvtColor(denoised, cv2.COLOR_BGR2HSV)
    
    # 增强饱和度
    hsv[:,:,1] = cv2.multiply(hsv[:,:,1], 1.5)
    # 增强亮度
    hsv[:,:,2] = cv2.multiply(hsv[:,:,2], 1.2)
    
    # 转换回BGR
    enhanced = cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)
    
    # 3. 使用双边滤波平滑颜色，同时保持边缘
    smoothed = cv2.bilateralFilter(enhanced, 9, 75, 75)
    
    # 4. 使用形态学操作连接相近的颜色区域
    kernel = np.ones((5,5), np.uint8)
    morphed = cv2.morphologyEx(smoothed, cv2.MORPH_CLOSE, kernel)
    
    # 5. 增强对比度
    lab = cv2.cvtColor(morphed, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
    cl = clahe.apply(l)
    enhanced_lab = cv2.merge((cl,a,b))
    final = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2BGR)
    
    return final

# 使用示例
if __name__ == "__main__":
    # 示例：从文件读取图像到内存
    img = cv2.imread("input.jpg")
    if img is not None:
        enhanced = enhance_image(img)
        # 显示结果
        cv2.imshow("Original", img)
        cv2.imshow("Enhanced", enhanced)
        cv2.waitKey(0)
        cv2.destroyAllWindows() 