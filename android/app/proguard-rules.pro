# Razorpay SDK Proguard rules
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep annotation classes used by Razorpay
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
