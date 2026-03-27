allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        val pluginName = project.name
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val clz = androidExt.javaClass
                val getNs = clz.getMethod("getNamespace")
                val ns = getNs.invoke(androidExt)
                if (ns == null || ns.toString().isEmpty()) {
                    val groupName = project.group.toString()
                    val setNs = clz.getMethod("setNamespace", String::class.java)
                    setNs.invoke(androidExt, if (groupName.isNotEmpty()) groupName else "com.example.$pluginName")
                }
            } catch (e: Exception) {
                // Ignore Reflection Exceptions
            }

            try {
                val clz = androidExt.javaClass
                val setCompileSdk = clz.getMethod("setCompileSdkVersion", Int::class.java)
                setCompileSdk.invoke(androidExt, 35)
            } catch (e: Exception) {
                // Ignore Reflection Exceptions
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
