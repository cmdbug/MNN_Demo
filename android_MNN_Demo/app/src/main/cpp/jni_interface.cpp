#include <jni.h>
#include <string>

#include "NanoDet.h"

#include <android/bitmap.h>
#include <android/log.h>
#include <opencv2/imgproc/types_c.h>

#ifndef LOG_TAG
#define LOG_TAG "WZT_MNN"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG ,__VA_ARGS__) // 定义LOGD类型
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,LOG_TAG ,__VA_ARGS__) // 定义LOGI类型
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN,LOG_TAG ,__VA_ARGS__) // 定义LOGW类型
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR,LOG_TAG ,__VA_ARGS__) // 定义LOGE类型
#define LOGF(...) __android_log_print(ANDROID_LOG_FATAL,LOG_TAG ,__VA_ARGS__) // 定义LOGF类型
#endif

/* ======================================[ NanoDet ]======================================*/
extern "C"
JNIEXPORT void JNICALL
Java_com_wzt_mnn_model_NanoDet_init(JNIEnv *env, jclass clazz, jstring name, jstring path, jboolean use_gpu) {
	if (NanoDet::detector != nullptr) {
        delete NanoDet::detector;
        NanoDet::detector = nullptr;
    }
    if (NanoDet::detector == nullptr) {
        const char *pathTemp = env->GetStringUTFChars(path, 0);
        std::string modelPath = pathTemp;
        if (modelPath.empty()) {
            LOGE("model path is null");
            return;
        }
        modelPath = modelPath + env->GetStringUTFChars(name, 0);
        LOGI("model path:%s", modelPath.c_str());
        NanoDet::detector = new NanoDet(modelPath, use_gpu);
    }
}

extern "C"
JNIEXPORT jobjectArray JNICALL
Java_com_wzt_mnn_model_NanoDet_detect(JNIEnv *env, jclass clazz, jobject bitmap, jbyteArray image_bytes, jint width,
                                      jint height, jdouble threshold, jdouble nms_threshold) {
    jbyte *imageDate = env->GetByteArrayElements(image_bytes, nullptr);
    if (nullptr == imageDate) {
        LOGE("input image is null");
        return nullptr;
    }
    // 输入参数bitmap为Bitmap, image_bytes为bitmap的byte[]
    AndroidBitmapInfo img_size;
    AndroidBitmap_getInfo(env, bitmap, &img_size);
    if (img_size.format != ANDROID_BITMAP_FORMAT_RGBA_8888) {
        LOGE("input image format not support");
        return nullptr;
    }
    auto *dataTemp = (unsigned char *) imageDate;
    cv::Mat srcMatImg;
    cv::Mat tempMat(height, width, CV_8UC4, dataTemp);
    cv::cvtColor(tempMat, srcMatImg, CV_RGBA2RGB);
    if (srcMatImg.channels() != 3) {
        LOGE("input image format channels != 3");
    }

    auto result = NanoDet::detector->detect(srcMatImg, (unsigned char *)imageDate, width, height, threshold, nms_threshold);

    srcMatImg.release();
    tempMat.release();
    env->ReleaseByteArrayElements(image_bytes, imageDate, 0);

    auto box_cls = env->FindClass("com/wzt/mnn/model/BoxInfo");
    auto cid = env->GetMethodID(box_cls, "<init>", "(FFFFIF)V");
    jobjectArray ret = env->NewObjectArray(result.size(), box_cls, nullptr);
    int i = 0;
    for (auto &box:result) {
        env->PushLocalFrame(1);
        jobject obj = env->NewObject(box_cls, cid, box.x1, box.y1, box.x2, box.y2, box.label, box.score);
        obj = env->PopLocalFrame(obj);
        env->SetObjectArrayElement(ret, i++, obj);
    }
    return ret;
}




