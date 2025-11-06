import cv2

# 读取图像并转换为200x200灰度图
img = cv2.imread(r"C:\Users\HP\Desktop\sobel\image\33c85cdb43c129c1c8125c5757b59bd6.jpg", 0)
img = cv2.resize(img, (200, 200))

# 生成input.image.txt文件
with open('input.image.txt', 'w') as f:
    for row in img:
        for pixel in row:
            f.write(f"{pixel}\n")

print("input.image.txt文件生成完成")