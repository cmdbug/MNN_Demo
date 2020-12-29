package com.wzt.mnn.model;

import android.graphics.Bitmap;

public class NanoDet {

    static {
        System.loadLibrary("tengmnn");
    }

    public static native void init(String name, String path, boolean useGPU);
    public static native BoxInfo[] detect(Bitmap bitmap, byte[] imageBytes, int width, int height, double threshold, double nms_threshold);
}
