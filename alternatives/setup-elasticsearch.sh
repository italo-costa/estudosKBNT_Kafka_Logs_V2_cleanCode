#!/bin/bash

################################################################################
# KBNT Elasticsearch Setup Script
# Configures indices, templates, and initial dashboards for the KBNT system
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ELASTICSEARCH_URL=${ELASTICSEARCH_URL:-"http://localhost:9200"}
KIBANA_URL=${KIBANA_URL:-"http://localhost:5601"}
INDEX_PATTERN="kbnt-consumption-logs"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

check_elasticsearch() {
    log "Checking Elasticsearch connectivity..."
    if curl -f "$ELASTICSEARCH_URL/_cluster/health" > /dev/null 2>&1; then
        log "✓ Elasticsearch is accessible"
        return 0
    else
        error "✗ Elasticsearch is not accessible at $ELASTICSEARCH_URL"
        return 1
    fi
}

check_kibana() {
    log "Checking Kibana connectivity..."
    if curl -f "$KIBANA_URL/api/status" > /dev/null 2>&1; then
        log "✓ Kibana is accessible"
        return 0
    else
        warn "⚠ Kibana is not accessible at $KIBANA_URL"
        return 1
    fi
}

create_index_template() {
    log "Creating index template for $INDEX_PATTERN..."
    
    curl -X PUT "$ELASTICSEARCH_URL/_index_template/kbnt-consumption-logs-template" \
         -H "Content-Type: application/json" \
         -d '{
  "index_patterns": ["'$INDEX_PATTERN'-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "index.lifecycle.name": "kbnt-logs-policy",
      "index.lifecycle.rollover_alias": "'$INDEX_PATTERN'",
      "index.refresh_interval": "5s",
      "index.mapping.total_fields.limit": 2000,
      "index.max_result_window": 50000
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date",
          "format": "strict_date_time||date_time"
        },
        "correlation_id": {
          "type": "keyword",
          "fields": {
            "text": {
              "type": "text"
            }
          }
        },
        "message_hash": {
          "type": "keyword"
        },
        "topic": {
          "type": "keyword"
        },
        "partition": {
          "type": "integer"
        },
        "offset": {
          "type": "long"
        },
        "product_id": {
          "type": "keyword",
          "fields": {
            "text": {
              "type": "text"
            }
          }
        },
        "quantity": {
          "type": "integer"
        },
        "price": {
          "type": "scaled_float",
          "scaling_factor": 100
        },
        "operation": {
          "type": "keyword"
        },
        "status": {
          "type": "keyword"
        },
        "processing_started_at": {
          "type": "date"
        },
        "processing_completed_at": {
          "type": "date"
        },
        "processing_time_ms": {
          "type": "long"
        },
        "api_response": {
          "properties": {
            "code": {
              "type": "integer"
            },
            "message": {
              "type": "text",
              "fields": {
                "keyword": {
                  "type": "keyword"
                }
              }
            },
            "duration_ms": {
              "type": "long"
            },
            "success": {
              "type": "boolean"
            }
          }
        },
        "external_api": {
          "properties": {
            "endpoint": {
              "type": "keyword"
            },
            "method": {
              "type": "keyword"
            },
            "response_time_ms": {
              "type": "long"
            },
            "provider": {
              "type": "keyword"
            }
          }
        },
        "error_message": {
          "type": "text",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "retry_count": {
          "type": "integer"
        },
        "priority": {
          "type": "keyword"
        },
        "environment": {
          "type": "keyword"
        },
        "consumer_instance": {
          "type": "keyword"
        },
        "version": {
          "type": "keyword"
        }
      }
    }
  }
}'
    
    if [ $? -eq 0 ]; then
        log "✓ Index template created successfully"
    else
        error "✗ Failed to create index template"
        return 1
    fi
}

create_ilm_policy() {
    log "Creating Index Lifecycle Management policy..."
    
    curl -X PUT "$ELASTICSEARCH_URL/_ilm/policy/kbnt-logs-policy" \
         -H "Content-Type: application/json" \
         -d '{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "5GB",
            "max_age": "1d"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "set_priority": {
            "priority": 50
          },
          "allocate": {
            "number_of_replicas": 0
          }
        }
      },
      "cold": {
        "min_age": "14d",
        "actions": {
          "set_priority": {
            "priority": 10
          },
          "allocate": {
            "number_of_replicas": 0
          }
        }
      },
      "delete": {
        "min_age": "30d"
      }
    }
  }
}'
    
    if [ $? -eq 0 ]; then
        log "✓ ILM policy created successfully"
    else
        error "✗ Failed to create ILM policy"
        return 1
    fi
}

create_initial_index() {
    log "Creating initial index with alias..."
    
    TODAY=$(date +'%Y.%m.%d')
    INITIAL_INDEX="$INDEX_PATTERN-$TODAY-000001"
    
    curl -X PUT "$ELASTICSEARCH_URL/$INITIAL_INDEX" \
         -H "Content-Type: application/json" \
         -d '{
  "settings": {
    "index.lifecycle.name": "kbnt-logs-policy",
    "index.lifecycle.rollover_alias": "'$INDEX_PATTERN'"
  },
  "aliases": {
    "'$INDEX_PATTERN'": {
      "is_write_index": true
    }
  }
}'
    
    if [ $? -eq 0 ]; then
        log "✓ Initial index $INITIAL_INDEX created with alias"
    else
        error "✗ Failed to create initial index"
        return 1
    fi
}

create_kibana_data_view() {
    if ! check_kibana; then
        warn "Skipping Kibana data view creation - Kibana not accessible"
        return 0
    fi
    
    log "Creating Kibana data view..."
    
    curl -X POST "$KIBANA_URL/api/data_views/data_view" \
         -H "Content-Type: application/json" \
         -H "kbn-xsrf: true" \
         -d '{
  "data_view": {
    "title": "'$INDEX_PATTERN'-*",
    "name": "KBNT Consumption Logs",
    "timeFieldName": "@timestamp"
  }
}'
    
    if [ $? -eq 0 ]; then
        log "✓ Kibana data view created successfully"
    else
        warn "⚠ Failed to create Kibana data view (may already exist)"
    fi
}

create_sample_dashboard() {
    if ! check_kibana; then
        warn "Skipping dashboard creation - Kibana not accessible"
        return 0
    fi
    
    log "Creating sample dashboard..."
    
    # This is a simplified dashboard creation
    # In practice, you would export from Kibana UI and import here
    log "ℹ Dashboard creation skipped - create manually in Kibana UI or import from exported dashboard"
}

setup_alerting() {
    log "Setting up Elasticsearch alerting/watcher..."
    
    curl -X PUT "$ELASTICSEARCH_URL/_watcher/watch/high-error-rate" \
         -H "Content-Type: application/json" \
         -d '{
  "trigger": {
    "schedule": {
      "interval": "5m"
    }
  },
  "input": {
    "search": {
      "request": {
        "search_type": "query_then_fetch",
        "indices": ["'$INDEX_PATTERN'-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "terms": {
                    "status.keyword": ["FAILED", "RETRY_EXHAUSTED"]
                  }
                },
                {
                  "range": {
                    "@timestamp": {
                      "gte": "now-5m"
                    }
                  }
                }
              ]
            }
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.hits.total": {
        "gt": 10
      }
    }
  },
  "actions": {
    "log_error_count": {
      "logging": {
        "text": "High error rate detected: {{ctx.payload.hits.total}} failed messages in last 5 minutes"
      }
    }
  }
}'
    
    if [ $? -eq 0 ]; then
        log "✓ Error rate alerting configured"
    else
        warn "⚠ Failed to create alerting rule (may require X-Pack license)"
    fi
}

validate_setup() {
    log "Validating Elasticsearch setup..."
    
    # Check if template exists
    if curl -f "$ELASTICSEARCH_URL/_index_template/kbnt-consumption-logs-template" > /dev/null 2>&1; then
        log "✓ Index template exists"
    else
        error "✗ Index template not found"
        return 1
    fi
    
    # Check if ILM policy exists
    if curl -f "$ELASTICSEARCH_URL/_ilm/policy/kbnt-logs-policy" > /dev/null 2>&1; then
        log "✓ ILM policy exists"
    else
        error "✗ ILM policy not found"
        return 1
    fi
    
    # Check if initial index exists
    if curl -f "$ELASTICSEARCH_URL/_alias/$INDEX_PATTERN" > /dev/null 2>&1; then
        log "✓ Index alias exists"
    else
        error "✗ Index alias not found"
        return 1
    fi
    
    log "✅ Elasticsearch setup validation completed successfully"
}

main() {
    log "🚀 Starting KBNT Elasticsearch setup..."
    log "Elasticsearch URL: $ELASTICSEARCH_URL"
    log "Kibana URL: $KIBANA_URL"
    log "Index Pattern: $INDEX_PATTERN"
    
    # Check prerequisites
    if ! check_elasticsearch; then
        error "Cannot proceed without Elasticsearch"
        exit 1
    fi
    
    # Create core components
    create_ilm_policy || exit 1
    create_index_template || exit 1
    create_initial_index || exit 1
    
    # Create Kibana components (optional)
    create_kibana_data_view
    create_sample_dashboard
    
    # Setup alerting (optional)
    setup_alerting
    
    # Validate everything
    validate_setup || exit 1
    
    log "🎉 KBNT Elasticsearch setup completed successfully!"
    log ""
    log "📊 Next steps:"
    log "  1. Access Kibana at $KIBANA_URL"
    log "  2. Create visualizations using the '$INDEX_PATTERN-*' data view"
    log "  3. Set up dashboards for monitoring"
    log "  4. Configure additional alerting rules"
    log ""
    log "📈 Useful URLs:"
    log "  - Elasticsearch: $ELASTICSEARCH_URL"
    log "  - Kibana: $KIBANA_URL"
    log "  - Index health: $ELASTICSEARCH_URL/_cat/indices/$INDEX_PATTERN-*?v"
    log "  - ILM status: $ELASTICSEARCH_URL/_cat/ilm/policies?v"
}

# Handle command line arguments
case "${1:-setup}" in
    "setup")
        main
        ;;
    "validate")
        check_elasticsearch && validate_setup
        ;;
    "cleanup")
        log "🧹 Cleaning up KBNT Elasticsearch resources..."
        curl -X DELETE "$ELASTICSEARCH_URL/_index_template/kbnt-consumption-logs-template"
        curl -X DELETE "$ELASTICSEARCH_URL/_ilm/policy/kbnt-logs-policy"
        curl -X DELETE "$ELASTICSEARCH_URL/$INDEX_PATTERN-*"
        log "✓ Cleanup completed"
        ;;
    *)
        echo "Usage: $0 [setup|validate|cleanup]"
        exit 1
        ;;
esac
