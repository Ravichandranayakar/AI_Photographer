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
        if (project.hasProperty("android")) {
            val android = project.property("android")!!
            try {
                val getNamespace = android::class.java.getMethod("getNamespace")
                val namespace = getNamespace.invoke(android)
                if (namespace == null) {
                    val setNamespace = android::class.java.getMethod("setNamespace", String::class.java)
                    // Generate a safe package name from the project name
                    val safeName = project.name.replace("-", "_").replace(":", "_")
                    setNamespace.invoke(android, "com.baroai.patch.$safeName")
                }
            } catch (e: Exception) {
                // Ignore errors if the methods don't exist
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
