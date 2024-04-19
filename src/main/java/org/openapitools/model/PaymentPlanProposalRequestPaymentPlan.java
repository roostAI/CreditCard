package org.openapitools.model;

import java.net.URI;
import java.util.Objects;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonTypeName;
import org.openapitools.jackson.nullable.JsonNullable;
import java.time.OffsetDateTime;
import javax.validation.Valid;
import javax.validation.constraints.*;
import io.swagger.v3.oas.annotations.media.Schema;


import java.util.*;
import javax.annotation.Generated;

/**
 * PaymentPlanProposalRequestPaymentPlan
 */

@JsonTypeName("paymentPlanProposal_request_paymentPlan")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class PaymentPlanProposalRequestPaymentPlan {

  private String installmentAmount;

  private String interestRate;

  private String termLength;

  public PaymentPlanProposalRequestPaymentPlan installmentAmount(String installmentAmount) {
    this.installmentAmount = installmentAmount;
    return this;
  }

  /**
   * Get installmentAmount
   * @return installmentAmount
  */
  
  @Schema(name = "installmentAmount", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("installmentAmount")
  public String getInstallmentAmount() {
    return installmentAmount;
  }

  public void setInstallmentAmount(String installmentAmount) {
    this.installmentAmount = installmentAmount;
  }

  public PaymentPlanProposalRequestPaymentPlan interestRate(String interestRate) {
    this.interestRate = interestRate;
    return this;
  }

  /**
   * Get interestRate
   * @return interestRate
  */
  
  @Schema(name = "interestRate", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("interestRate")
  public String getInterestRate() {
    return interestRate;
  }

  public void setInterestRate(String interestRate) {
    this.interestRate = interestRate;
  }

  public PaymentPlanProposalRequestPaymentPlan termLength(String termLength) {
    this.termLength = termLength;
    return this;
  }

  /**
   * Get termLength
   * @return termLength
  */
  
  @Schema(name = "termLength", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("termLength")
  public String getTermLength() {
    return termLength;
  }

  public void setTermLength(String termLength) {
    this.termLength = termLength;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    PaymentPlanProposalRequestPaymentPlan paymentPlanProposalRequestPaymentPlan = (PaymentPlanProposalRequestPaymentPlan) o;
    return Objects.equals(this.installmentAmount, paymentPlanProposalRequestPaymentPlan.installmentAmount) &&
        Objects.equals(this.interestRate, paymentPlanProposalRequestPaymentPlan.interestRate) &&
        Objects.equals(this.termLength, paymentPlanProposalRequestPaymentPlan.termLength);
  }

  @Override
  public int hashCode() {
    return Objects.hash(installmentAmount, interestRate, termLength);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class PaymentPlanProposalRequestPaymentPlan {\n");
    sb.append("    installmentAmount: ").append(toIndentedString(installmentAmount)).append("\n");
    sb.append("    interestRate: ").append(toIndentedString(interestRate)).append("\n");
    sb.append("    termLength: ").append(toIndentedString(termLength)).append("\n");
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

