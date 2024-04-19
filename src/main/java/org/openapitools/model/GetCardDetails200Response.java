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
 * GetCardDetails200Response
 */

@JsonTypeName("getCardDetails_200_response")
@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
public class GetCardDetails200Response {

  private String cardNumberPartial;

  public GetCardDetails200Response cardNumberPartial(String cardNumberPartial) {
    this.cardNumberPartial = cardNumberPartial;
    return this;
  }

  /**
   * Get cardNumberPartial
   * @return cardNumberPartial
  */
  
  @Schema(name = "cardNumberPartial", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
  @JsonProperty("cardNumberPartial")
  public String getCardNumberPartial() {
    return cardNumberPartial;
  }

  public void setCardNumberPartial(String cardNumberPartial) {
    this.cardNumberPartial = cardNumberPartial;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    GetCardDetails200Response getCardDetails200Response = (GetCardDetails200Response) o;
    return Objects.equals(this.cardNumberPartial, getCardDetails200Response.cardNumberPartial);
  }

  @Override
  public int hashCode() {
    return Objects.hash(cardNumberPartial);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("class GetCardDetails200Response {\n");
    sb.append("    cardNumberPartial: ").append(toIndentedString(cardNumberPartial)).append("\n");
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

