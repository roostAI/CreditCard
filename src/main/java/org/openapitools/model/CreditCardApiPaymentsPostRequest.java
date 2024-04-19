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
 * CreditCardApiPaymentsPostRequest
 */

@JsonTypeName("_credit_card_api_payments_post_request")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T11:57:54.777818+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class CreditCardApiPaymentsPostRequest {

  private String cardNumber;

  private BigDecimal amount;

  public CreditCardApiPaymentsPostRequest cardNumber(String cardNumber) {
    this.cardNumber = cardNumber;
    return this;
  }

  /**
   * Get cardNumber
   * @return cardNumber
  */
  @Pattern(regexp = "^[0-9]{10}$") 
  @Schema(name = "CardNumber", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("CardNumber")
  public String getCardNumber() {
    return cardNumber;
  }

  public void setCardNumber(String cardNumber) {
    this.cardNumber = cardNumber;
  }

  public CreditCardApiPaymentsPostRequest amount(BigDecimal amount) {
    this.amount = amount;
    return this;
  }

  /**
   * Get amount
   * @return amount
  */
  @Valid 
  @Schema(name = "Amount", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("Amount")
  public BigDecimal getAmount() {
    return amount;
  }

  public void setAmount(BigDecimal amount) {
    this.amount = amount;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    CreditCardApiPaymentsPostRequest creditCardApiPaymentsPostRequest = (CreditCardApiPaymentsPostRequest) o;
    return Objects.equals(this.cardNumber, creditCardApiPaymentsPostRequest.cardNumber) &&
        Objects.equals(this.amount, creditCardApiPaymentsPostRequest.amount);
  }

  @Override
  public int hashCode() {
    return Objects.hash(cardNumber, amount);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class CreditCardApiPaymentsPostRequest {\n");
    sb.append("    cardNumber: ").append(toIndentedString(cardNumber)).append("\n");
    sb.append("    amount: ").append(toIndentedString(amount)).append("\n");
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

