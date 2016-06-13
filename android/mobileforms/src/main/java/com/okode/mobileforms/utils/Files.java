package com.okode.mobileforms.utils;

import android.util.Log;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;

public class Files {

    public static String readTextFile(String path) {
        InputStream is = null;
        try {
            return readTextFile(is = new FileInputStream(path));
        } catch (FileNotFoundException e) {
            Log.e("MobileForms", "File not found: '" + path + "'. Cause: " + e.getMessage());
            return null;
        } finally {
            if (is != null) try {
                is.close();
            } catch (IOException e) { }
        }

    }

    public static String readTextFile(InputStream is) {
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
            StringBuffer buffer = new StringBuffer();
            String line;
            while ((line = reader.readLine()) != null) {
                buffer.append(line);
            }
            return buffer.toString();
        } catch (IOException e) {
            Log.e("MobileForms", "Could not read input stream. Cause: " + e.getMessage());
            return null;
        }
    }

}