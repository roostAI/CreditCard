package org.openapitools.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonTypeName;
import org.openapitools.model.PaymentPlanProposalRequestPaymentPlan;
import org.openapitools.jackson.nullable.JsonNullable;
import java.time.OffsetDateTime;
import javax.validation.Valid;
import javax.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;


import java.util.*;
import javax.annotation.Generated;

/**
 * PaymentPlanProposalRequest
 */

@JsonTypeName("paymentPlanProposal_request")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class PaymentPlanProposalRequest {

  private String outstandingBalance;

  private PaymentPlanProposalRequestPaymentPlan paymentPlan;

  private String cardLast4;

  public PaymentPlanProposalRequest() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public PaymentPlanProposalRequest(String outstandingBalance, PaymentPlanProposalRequestPaymentPlan paymentPlan, String cardLast4) {
    this.outstandingBalance = outstandingBalance;
    this.paymentPlan = paymentPlan;
    this.cardLast4 = cardLast4;
  }

  public PaymentPlanProposalRequest outstandingBalance(String outstandingBalance) {
    this.outstandingBalance = outstandingBalance;
    return this;
  }

  /**
   * Get outstandingBalance
   * @return outstandingBalance
  */
  @NotNull 
  @Schema(name = "outstandingBalance", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("outstandingBalance")
  public String getOutstandingBalance() {
    return outstandingBalance;
  }

  public void setOutstandingBalance(String outstandingBalance) {
    this.outstandingBalance = outstandingBalance;
  }

  public PaymentPlanProposalRequest paymentPlan(PaymentPlanProposalRequestPaymentPlan paymentPlan) {
    this.paymentPlan = paymentPlan;
    return this;
  }

  /**
   * Get paymentPlan
   * @return paymentPlan
  */
  @NotNull @Valid 
  @Schema(name = "paymentPlan", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("paymentPlan")
  public PaymentPlanProposalRequestPaymentPlan getPaymentPlan() {
    return paymentPlan;
  }

  public void setPaymentPlan(PaymentPlanProposalRequestPaymentPlan paymentPlan) {
    this.paymentPlan = paymentPlan;
  }

  public PaymentPlanProposalRequest cardLast4(String cardLast4) {
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
    PaymentPlanProposalRequest paymentPlanProposalRequest = (PaymentPlanProposalRequest) o;
    return Objects.equals(this.outstandingBalance, paymentPlanProposalRequest.outstandingBalance) &&
        Objects.equals(this.paymentPlan, paymentPlanProposalRequest.paymentPlan) &&
        Objects.equals(this.cardLast4, paymentPlanProposalRequest.cardLast4);
  }

  @Override
  public int hashCode() {
    return Objects.hash(outstandingBalance, paymentPlan, cardLast4);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class PaymentPlanProposalRequest {\n");
    sb.append("    outstandingBalance: ").append(toIndentedString(outstandingBalance)).append("\n");
    sb.append("    paymentPlan: ").append(toIndentedString(paymentPlan)).append("\n");
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

