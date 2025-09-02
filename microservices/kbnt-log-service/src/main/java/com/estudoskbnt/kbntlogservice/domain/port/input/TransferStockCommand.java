package com.estudoskbnt.kbntlogservice.domain.port.input;

import com.estudoskbnt.kbntlogservice.domain.model.*;

/**
 * Transfer Stock Command Interface
 * 
 * Specific command interface for stock transfer operations.
 */
public interface TransferStockCommand extends StockUpdateCommand {
  SourceBranch getSourceBranch();
}
