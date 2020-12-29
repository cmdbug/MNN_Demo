package com.wzt.mnn.activity;

import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Toast;
import android.widget.ToggleButton;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.wzt.mnn.R;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class WelcomeActivity extends AppCompatActivity {

    private ToggleButton tbUseGpu;
    private Button btnNanoDet;

    private boolean useGPU = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);

        findView();
        initView();
        copyModelFromAssetsToData();
    }

    protected void copyModelFromAssetsToData() {
        // assets目录的下模型文件名
        String[] models = {
                "nanodet_320.mnn"
        };

        Toast.makeText(this, "Copy model to data...", Toast.LENGTH_SHORT).show();
        try {
            for (String model : models) {
                copyAssetFileToFiles(this, model);
            }
            enableButtons();
            Toast.makeText(this, "Copy model Success", Toast.LENGTH_SHORT).show();
        } catch (Exception e) {
            e.printStackTrace();
            Toast.makeText(this, "Copy model Error", Toast.LENGTH_SHORT).show();
        }
    }

    protected void findView() {
        tbUseGpu = findViewById(R.id.tb_use_gpu);
        btnNanoDet = findViewById(R.id.btn_start_detect1);

        btnNanoDet.setEnabled(false);
    }

    private void enableButtons() {
        btnNanoDet.setEnabled(true);
    }

    protected void initView() {
        tbUseGpu.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                useGPU = isChecked;
                MainActivity.USE_GPU = useGPU;
                if (useGPU) {
                    AlertDialog.Builder builder = new AlertDialog.Builder(WelcomeActivity.this);
                    builder.setTitle("Warning");
                    builder.setMessage("If the GPU is too old, it may not work well in GPU mode.");
                    builder.setCancelable(true);
                    builder.setPositiveButton("OK", null);
                    AlertDialog dialog = builder.create();
                    dialog.show();
                } else {
                    Toast.makeText(WelcomeActivity.this, "CPU mode", Toast.LENGTH_SHORT).show();
                }
            }
        });

        btnNanoDet.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                MainActivity.USE_MODEL = MainActivity.NANODET;
                Intent intent = new Intent(WelcomeActivity.this, MainActivity.class);
                WelcomeActivity.this.startActivity(intent);
            }
        });
    }

    public void copyAssetDirToFiles(Context context, String dirname) throws IOException {
        File dir = new File(context.getFilesDir() + File.separator + dirname);
        dir.mkdir();

        AssetManager assetManager = context.getAssets();
        String[] children = assetManager.list(dirname);
        for (String child : children) {
            child = dirname + File.separator + child;
            String[] grandChildren = assetManager.list(child);
            if (0 == grandChildren.length) {
                copyAssetFileToFiles(context, child);
            } else {
                copyAssetDirToFiles(context, child);
            }
        }
    }

    public void copyAssetFileToFiles(Context context, String filename) throws IOException {
        InputStream is = context.getAssets().open(filename);
        byte[] buffer = new byte[is.available()];
        is.read(buffer);
        is.close();

        File of = new File(context.getFilesDir() + File.separator + filename);
        of.createNewFile();
        FileOutputStream os = new FileOutputStream(of);
        os.write(buffer);
        os.close();
    }

}