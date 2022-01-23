package com.app.hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;


@SpringBootApplication
@RestController
public class HelloApplication {

	@GetMapping("/")
	public String index() {
		return "Testing webhook";
	}
	
	public static void main(String[] args) {
		SpringApplication.run(HelloApplication.class, args);
	}

}
