package com.wzt.mnn.model;

import android.graphics.Color;
import android.graphics.RectF;

import java.util.Random;

public class BoxInfo {

    public float x0, y0, x1, y1;
    private final int label;
    private final float score;
    private static final String[] labels = {"person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light",
            "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow",
            "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
            "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard",
            "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
            "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
            "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone",
            "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear",
            "hair drier", "toothbrush"};

    public BoxInfo(float x0, float y0, float x1, float y1, int label, float score) {
        this.x0 = x0;
        this.y0 = y0;
        this.x1 = x1;
        this.y1 = y1;
        this.label = label;
        this.score = score;
    }

    public RectF getRect() {
        return new RectF(x0, y0, x1, y1);
    }

    public String getLabel() {
        return labels[label];
    }

    public float getScore() {
        return score;
    }

    public int getColor() {
        Random random = new Random(label);
        return Color.argb(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
    }

}
