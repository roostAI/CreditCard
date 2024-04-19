package org.openapitools.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonTypeName;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import org.openapitools.jackson.nullable.JsonNullable;
import java.time.OffsetDateTime;
import javax.validation.Valid;
import javax.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;


import java.util.*;
import javax.annotation.Generated;

/**
 * PaymentReminderRequest
 */

@JsonTypeName("paymentReminder_request")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class PaymentReminderRequest {

  @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
  private LocalDate currentDate;

  @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
  private LocalDate paymentDueDate;

  private String cardLast4;

  public PaymentReminderRequest() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public PaymentReminderRequest(LocalDate currentDate, LocalDate paymentDueDate, String cardLast4) {
    this.currentDate = currentDate;
    this.paymentDueDate = paymentDueDate;
    this.cardLast4 = cardLast4;
  }

  public PaymentReminderRequest currentDate(LocalDate currentDate) {
    this.currentDate = currentDate;
    return this;
  }

  /**
   * Get currentDate
   * @return currentDate
  */
  @NotNull @Valid 
  @Schema(name = "currentDate", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("currentDate")
  public LocalDate getCurrentDate() {
    return currentDate;
  }

  public void setCurrentDate(LocalDate currentDate) {
    this.currentDate = currentDate;
  }

  public PaymentReminderRequest paymentDueDate(LocalDate paymentDueDate) {
    this.paymentDueDate = paymentDueDate;
    return this;
  }

  /**
   * Get paymentDueDate
   * @return paymentDueDate
  */
  @NotNull @Valid 
  @Schema(name = "paymentDueDate", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("paymentDueDate")
  public LocalDate getPaymentDueDate() {
    return paymentDueDate;
  }

  public void setPaymentDueDate(LocalDate paymentDueDate) {
    this.paymentDueDate = paymentDueDate;
  }

  public PaymentReminderRequest cardLast4(String cardLast4) {
    this.cardLast4 = cardLast4;
    return this;
  }

  /**
   * Get cardLast4
   * @return cardLast4
  */
  @NotNull @Size(min = 4, max = 4) 
  @Schema(name = "cardLast4", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("cardLast4")
  public String getCardLast4() {
    return cardLast4;
  }

  public void setCardLast4(String cardLast4) {
    this.cardLast4 = cardLast4;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    PaymentReminderRequest paymentReminderRequest = (PaymentReminderRequest) o;
    return Objects.equals(this.currentDate, paymentReminderRequest.currentDate) &&
        Objects.equals(this.paymentDueDate, paymentReminderRequest.paymentDueDate) &&
        Objects.equals(this.cardLast4, paymentReminderRequest.cardLast4);
  }

  @Override
  public int hashCode() {
    return Objects.hash(currentDate, paymentDueDate, cardLast4);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class PaymentReminderRequest {\n");
    sb.append("    currentDate: ").append(toIndentedString(currentDate)).append("\n");
    sb.append("    paymentDueDate: ").append(toIndentedString(paymentDueDate)).append("\n");
    sb.append("    cardLast4: ").append(toIndentedString(cardLast4)).append("\n");
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

