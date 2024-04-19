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
 * CollectionNotificationRequest
 */

@JsonTypeName("collectionNotification_request")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class CollectionNotificationRequest {

  private String delinquencyStatus;

  private String outstandingBalance;

  private String additionalCharges;

  private String cardLast4;

  public CollectionNotificationRequest() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public CollectionNotificationRequest(String delinquencyStatus, String outstandingBalance, String additionalCharges, String cardLast4) {
    this.delinquencyStatus = delinquencyStatus;
    this.outstandingBalance = outstandingBalance;
    this.additionalCharges = additionalCharges;
    this.cardLast4 = cardLast4;
  }

  public CollectionNotificationRequest delinquencyStatus(String delinquencyStatus) {
    this.delinquencyStatus = delinquencyStatus;
    return this;
  }

  /**
   * Get delinquencyStatus
   * @return delinquencyStatus
  */
  @NotNull 
  @Schema(name = "delinquencyStatus", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("delinquencyStatus")
  public String getDelinquencyStatus() {
    return delinquencyStatus;
  }

  public void setDelinquencyStatus(String delinquencyStatus) {
    this.delinquencyStatus = delinquencyStatus;
  }

  public CollectionNotificationRequest outstandingBalance(String outstandingBalance) {
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

  public CollectionNotificationRequest additionalCharges(String additionalCharges) {
    this.additionalCharges = additionalCharges;
    return this;
  }

  /**
   * Get additionalCharges
   * @return additionalCharges
  */
  @NotNull 
  @Schema(name = "additionalCharges", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("additionalCharges")
  public String getAdditionalCharges() {
    return additionalCharges;
  }

  public void setAdditionalCharges(String additionalCharges) {
    this.additionalCharges = additionalCharges;
  }

  public CollectionNotificationRequest cardLast4(String cardLast4) {
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
    CollectionNotificationRequest collectionNotificationRequest = (CollectionNotificationRequest) o;
    return Objects.equals(this.delinquencyStatus, collectionNotificationRequest.delinquencyStatus) &&
        Objects.equals(this.outstandingBalance, collectionNotificationRequest.outstandingBalance) &&
        Objects.equals(this.additionalCharges, collectionNotificationRequest.additionalCharges) &&
        Objects.equals(this.cardLast4, collectionNotificationRequest.cardLast4);
  }

  @Override
  public int hashCode() {
    return Objects.hash(delinquencyStatus, outstandingBalance, additionalCharges, cardLast4);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class CollectionNotificationRequest {\n");
    sb.append("    delinquencyStatus: ").append(toIndentedString(delinquencyStatus)).append("\n");
    sb.append("    outstandingBalance: ").append(toIndentedString(outstandingBalance)).append("\n");
    sb.append("    additionalCharges: ").append(toIndentedString(additionalCharges)).append("\n");
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

