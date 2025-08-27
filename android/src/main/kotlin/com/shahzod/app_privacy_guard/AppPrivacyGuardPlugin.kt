package com.shahzod.app_privacy_guard

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.RenderEffect
import android.graphics.Shader
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AppPrivacyGuardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    private var snapshotView: ImageView? = null
    private var dimView: View? = null
    private var secureEnabled = false

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "app_privacy_guard")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enableBlur" -> {
                attachBlurSnapshot(); result.success(null)
            }

            "disableBlur" -> {
                removeBlurSnapshot(); result.success(null)
            }

            "enableSecure" -> {
                setSecure(true); result.success(null)
            }

            "disableSecure" -> {
                setSecure(false); result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // --- Core: take snapshot of current UI and blur it as an overlay ---
    private fun attachBlurSnapshot() {
        val act = activity ?: return
        val root = act.window?.decorView as? ViewGroup ?: return
        if (snapshotView != null) return

        val bmp = captureRootBitmap(root) ?: run {
            // Agar bitmap olinmasa — dim fallback
            attachDim(root, alpha = 0xCC)
            return
        }

        val iv = ImageView(act)
        iv.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
        )
        iv.scaleType = ImageView.ScaleType.CENTER_CROP
        iv.setImageBitmap(bmp)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            iv.setRenderEffect(RenderEffect.createBlurEffect(25f, 25f, Shader.TileMode.CLAMP))
        } else {
            // <31: haqiqiy blur yo‘q — kuchli dim bilan yopamiz
            // (xohlasangiz bu yerda custom fast blur (stack blur) ham qo‘shish mumkin)
            attachDim(root, alpha = 0xDD)
        }

        // Touch bloklansin
        iv.isClickable = true
        iv.isFocusable = true

        root.addView(iv)
        snapshotView = iv

        // Qo‘shimcha kontrast uchun engil dim (API31+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            attachDim(root, alpha = 0x55)
        }
    }

    private fun removeBlurSnapshot() {
        val root = activity?.window?.decorView as? ViewGroup ?: return
        snapshotView?.let { root.removeView(it) }
        snapshotView = null
        removeDim()
    }

    private fun captureRootBitmap(root: ViewGroup): Bitmap? {
        return try {
            // Recent thumbnail odatda shu view ierarxiyasidan olinadi:
            val w = root.width.takeIf { it > 0 } ?: return null
            val h = root.height.takeIf { it > 0 } ?: return null

            // Performance uchun downscale (masalan 0.5x)
            val scale = 0.5f
            val bw = (w * scale).toInt().coerceAtLeast(1)
            val bh = (h * scale).toInt().coerceAtLeast(1)

            val bitmap = Bitmap.createBitmap(bw, bh, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.scale(scale, scale)
            root.draw(canvas) // FlutterView ham shu yerda chiziladi
            bitmap
        } catch (_: Throwable) {
            null
        }
    }

    private fun attachDim(root: ViewGroup, alpha: Int) {
        if (dimView != null) return
        dimView = View(root.context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor((alpha shl 24) or 0x000000)
            isClickable = true
            isFocusable = true
        }
        root.addView(dimView)
    }

    private fun removeDim() {
        val root = activity?.window?.decorView as? ViewGroup ?: return
        dimView?.let { root.removeView(it) }
        dimView = null
    }

    private fun setSecure(enable: Boolean) {
        val win = activity?.window ?: return
        if (secureEnabled == enable) return
        secureEnabled = enable
        if (enable) {
            win.setFlags(
                android.view.WindowManager.LayoutParams.FLAG_SECURE,
                android.view.WindowManager.LayoutParams.FLAG_SECURE
            )
        } else {
            win.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
