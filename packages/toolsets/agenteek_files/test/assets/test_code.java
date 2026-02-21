package com.x.y.z;

public class CoreException extends Exception {

	private String code = "non-initialisé";

	public CoreException() {
		super();
	}

	public CoreException(String code) {
		super();
		this.code = code;
	}

	public String getCode() {
		return code;
	}
}

