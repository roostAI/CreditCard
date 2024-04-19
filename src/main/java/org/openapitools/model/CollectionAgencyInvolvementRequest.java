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
 * CollectionAgencyInvolvementRequest
 */

@JsonTypeName("collectionAgencyInvolvement_request")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class CollectionAgencyInvolvementRequest {

  private String previousNotifications;

  private String responseStatus;

  private String cardLast4;

  public CollectionAgencyInvolvementRequest() {
    super();
  }

  /**
   * Constructor with only required parameters
   */
  public CollectionAgencyInvolvementRequest(String previousNotifications, String responseStatus, String cardLast4) {
    this.previousNotifications = previousNotifications;
    this.responseStatus = responseStatus;
    this.cardLast4 = cardLast4;
  }

  public CollectionAgencyInvolvementRequest previousNotifications(String previousNotifications) {
    this.previousNotifications = previousNotifications;
    return this;
  }

  /**
   * Get previousNotifications
   * @return previousNotifications
  */
  @NotNull 
  @Schema(name = "previousNotifications", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("previousNotifications")
  public String getPreviousNotifications() {
    return previousNotifications;
  }

  public void setPreviousNotifications(String previousNotifications) {
    this.previousNotifications = previousNotifications;
  }

  public CollectionAgencyInvolvementRequest responseStatus(String responseStatus) {
    this.responseStatus = responseStatus;
    return this;
  }

  /**
   * Get responseStatus
   * @return responseStatus
  */
  @NotNull 
  @Schema(name = "responseStatus", requiredMode = Schema.RequiredMode.REQUIRED)
  @JsonProperty("responseStatus")
  public String getResponseStatus() {
    return responseStatus;
  }

  public void setResponseStatus(String responseStatus) {
    this.responseStatus = responseStatus;
  }

  public CollectionAgencyInvolvementRequest cardLast4(String cardLast4) {
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
    CollectionAgencyInvolvementRequest collectionAgencyInvolvementRequest = (CollectionAgencyInvolvementRequest) o;
    return Objects.equals(this.previousNotifications, collectionAgencyInvolvementRequest.previousNotifications) &&
        Objects.equals(this.responseStatus, collectionAgencyInvolvementRequest.responseStatus) &&
        Objects.equals(this.cardLast4, collectionAgencyInvolvementRequest.cardLast4);
  }

  @Override
  public int hashCode() {
    return Objects.hash(previousNotifications, responseStatus, cardLast4);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class CollectionAgencyInvolvementRequest {\n");
    sb.append("    previousNotifications: ").append(toIndentedString(previousNotifications)).append("\n");
    sb.append("    responseStatus: ").append(toIndentedString(responseStatus)).append("\n");
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

