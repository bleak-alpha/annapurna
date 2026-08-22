package com.annapurna.model;

import com.annapurna.dto.Order.OrderDetails;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "INA_CANTEEN_AUDIT")
public class InaAuditTable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "CUSTOMER_NAME")
    private String customerName;

    @Column(name = "CUSTOMER_ID")
    private String customerId;

    @Column(name = "EAT_MODE")
    private String eatMode;

    /*
    In this Column stored order details in List of (String and Integer Formate)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "ORDER_ITEMS", columnDefinition = "json")
    private List<OrderDetails> orderDetails;

    @Column(name = "TOTAL_PAYMENT")
    private Integer totalPayment;

    @Column(name = "PAID_AMOUNT")
    private Integer paidAmount;

    @Column(name = "REMAINING_AMOUNT")
    private Integer remainingAmount;

    @Column(name = "PAYMENT_MODE")
    private String paymentMode;

    @Column(name = "ORDER_STATUS")
    private String orderStatus;

    @Column(name = "CREATED_DATE")
    private LocalDateTime createdDate;

    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;

    /*
    In this column add status for schedulers 0= Success, 2= Need to Update Data, 3= Failed To Update
     */
    @Column(name="TABLE_UPDATE_STATUS")
    private String tableUpdateStatus;

    @Column(name = "DUE_PAID_AMOUNT")
    private int duePaidAmount;
    
}