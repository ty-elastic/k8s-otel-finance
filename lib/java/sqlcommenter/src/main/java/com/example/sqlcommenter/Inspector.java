// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.example.sqlcommenter;

import org.hibernate.resource.jdbc.spi.StatementInspector;

public class Inspector implements StatementInspector {

  @Override
  public String inspect(String sql) {
    State state = null;

    // Priority for OpenTelemetry commenting
    io.opentelemetry.api.trace.SpanContext spanContextOT =
        io.opentelemetry.api.trace.Span.current().getSpanContext();

    if (spanContextOT.isValid()) {
      if (spanContextOT.isSampled()) {
        state =
            State.newBuilder()
                .withSpanContextMetadata(
                    SpanContextMetadata.fromOpenTelemetryContext(spanContextOT))
                .build();
      }
    }

    if (state == null) return sql;

    return state.formatAndAppendToSQL(sql);
  }
}
