package com.estudoskbnt.kbntlogservice.domain.port.input;

import com.estudoskbnt.kbntlogservice.domain.model.*;

/**
 * Base Stock Update Command Interface
 * 
 * Defines the basic contract for all stock update operations.
 */
public interface StockUpdateCommand {
  ProductId getProductId();
  DistributionCenter getDistributionCenter();
  Branch getBranch();
  Quantity getQuantity();
  Operation getOperation();
  CorrelationId getCorrelationId();
  ReasonCode getReasonCode();
  ReferenceDocument getReferenceDocument();
}
