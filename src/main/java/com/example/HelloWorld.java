package com.example;

public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello World from Jenkins CI/CD Pipeline!");
        System.out.println("Application version: 1.0.0");
        System.out.println("Build timestamp: " + java.time.LocalDateTime.now());
    }
}
