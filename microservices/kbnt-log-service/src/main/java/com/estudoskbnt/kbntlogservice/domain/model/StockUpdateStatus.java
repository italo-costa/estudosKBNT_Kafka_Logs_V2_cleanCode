package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Stock Update Status - Processing status
 */
public enum StockUpdateStatus {
  PENDING,
  PROCESSING,
  PROCESSED,
  FAILED,
  CANCELLED
}
