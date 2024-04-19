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
 * LegalActionInitiationRequest
 */

@JsonTypeName("legalActionInitiation_request")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class LegalActionInitiationRequest {

  private String nonPaymentStatus;

  private String legalStatus;

  private String cardLast4;

  public LegalActionInitiationRequest() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public LegalActionInitiationRequest(String nonPaymentStatus, String legalStatus, String cardLast4) {
    this.nonPaymentStatus = nonPaymentStatus;
    this.legalStatus = legalStatus;
    this.cardLast4 = cardLast4;
  }

  public LegalActionInitiationRequest nonPaymentStatus(String nonPaymentStatus) {
    this.nonPaymentStatus = nonPaymentStatus;
    return this;
  }

  /**
   * Get nonPaymentStatus
   * @return nonPaymentStatus
  */
  @NotNull 
  @Schema(name = "nonPaymentStatus", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("nonPaymentStatus")
  public String getNonPaymentStatus() {
    return nonPaymentStatus;
  }

  public void setNonPaymentStatus(String nonPaymentStatus) {
    this.nonPaymentStatus = nonPaymentStatus;
  }

  public LegalActionInitiationRequest legalStatus(String legalStatus) {
    this.legalStatus = legalStatus;
    return this;
  }

  /**
   * Get legalStatus
   * @return legalStatus
  */
  @NotNull 
  @Schema(name = "legalStatus", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("legalStatus")
  public String getLegalStatus() {
    return legalStatus;
  }

  public void setLegalStatus(String legalStatus) {
    this.legalStatus = legalStatus;
  }

  public LegalActionInitiationRequest cardLast4(String cardLast4) {
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
    LegalActionInitiationRequest legalActionInitiationRequest = (LegalActionInitiationRequest) o;
    return Objects.equals(this.nonPaymentStatus, legalActionInitiationRequest.nonPaymentStatus) &&
        Objects.equals(this.legalStatus, legalActionInitiationRequest.legalStatus) &&
        Objects.equals(this.cardLast4, legalActionInitiationRequest.cardLast4);
  }

  @Override
  public int hashCode() {
    return Objects.hash(nonPaymentStatus, legalStatus, cardLast4);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class LegalActionInitiationRequest {\n");
    sb.append("    nonPaymentStatus: ").append(toIndentedString(nonPaymentStatus)).append("\n");
    sb.append("    legalStatus: ").append(toIndentedString(legalStatus)).append("\n");
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

