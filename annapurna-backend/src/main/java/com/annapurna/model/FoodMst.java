package com.annapurna.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "FOO_FOOD_MST")
@Data
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class FoodMst {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "item_id")
    private Integer itemId;
    
    @Column(name = "item_code", unique = true, nullable = false)
    private String itemCode;
    
    @Column(name = "item_description", nullable = false)
    private String itemDescription;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
    
    @Column(name = "in_use")
    private Boolean inUse = true;
}