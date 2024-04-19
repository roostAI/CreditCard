package org.openapitools.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonTypeName;
import java.math.BigDecimal;
import org.openapitools.jackson.nullable.JsonNullable;
import java.time.OffsetDateTime;
import javax.validation.Valid;
import javax.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;


import java.util.*;
import javax.annotation.Generated;

/**
 * CreditCardApiPaymentsPost200Response
 */

@JsonTypeName("_credit_card_api_payments_post_200_response")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T11:57:54.777818+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class CreditCardApiPaymentsPost200Response {

  private String message;

  private BigDecimal newBalance;

  public CreditCardApiPaymentsPost200Response message(String message) {
    this.message = message;
    return this;
  }

  /**
   * Get message
   * @return message
  */
  
  @Schema(name = "message", example = "Payment successful", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("message")
  public String getMessage() {
    return message;
  }

  public void setMessage(String message) {
    this.message = message;
  }

  public CreditCardApiPaymentsPost200Response newBalance(BigDecimal newBalance) {
    this.newBalance = newBalance;
    return this;
  }

  /**
   * Get newBalance
   * @return newBalance
  */
  @Valid 
  @Schema(name = "newBalance", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("newBalance")
  public BigDecimal getNewBalance() {
    return newBalance;
  }

  public void setNewBalance(BigDecimal newBalance) {
    this.newBalance = newBalance;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    CreditCardApiPaymentsPost200Response creditCardApiPaymentsPost200Response = (CreditCardApiPaymentsPost200Response) o;
    return Objects.equals(this.message, creditCardApiPaymentsPost200Response.message) &&
        Objects.equals(this.newBalance, creditCardApiPaymentsPost200Response.newBalance);
  }

  @Override
  public int hashCode() {
    return Objects.hash(message, newBalance);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class CreditCardApiPaymentsPost200Response {\n");
    sb.append("    message: ").append(toIndentedString(message)).append("\n");
    sb.append("    newBalance: ").append(toIndentedString(newBalance)).append("\n");
    sb.append("}");
    return sb.toString();
  }

  /**
   * Convert the given object to string with each line indented by 4 spaces
   * (except the first line).
   */
  private String toIndentedString(Object o) {
    if (o == null) {
      return "null";
    }
    return o.toString().replace("\n", "\n    ");
  }
}

