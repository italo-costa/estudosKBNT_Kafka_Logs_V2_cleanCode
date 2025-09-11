package com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto;

public class ApiResponse<T> {
	private boolean success;
	private T data;
	private String message;
	private String timestamp;

	public ApiResponse() {}
	public ApiResponse(boolean success, T data, String message, String timestamp) {
		this.success = success;
		this.data = data;
		this.message = message;
		this.timestamp = timestamp;
	}
	public boolean isSuccess() { return success; }
	public T getData() { return data; }
	public String getMessage() { return message; }
	public String getTimestamp() { return timestamp; }
	public void setSuccess(boolean success) { this.success = success; }
	public void setData(T data) { this.data = data; }
	public void setMessage(String message) { this.message = message; }
	public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
	public static <T> ApiResponse<T> success(T data, String message) {
		return new ApiResponse<>(true, data, message, java.time.LocalDateTime.now().toString());
	}
	public static <T> ApiResponse<T> error(String message) {
		return new ApiResponse<>(false, null, message, java.time.LocalDateTime.now().toString());
	}
}
