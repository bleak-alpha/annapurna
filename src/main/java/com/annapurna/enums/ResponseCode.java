package com.annapurna.enums;

public enum ResponseCode {

    INA_CANTEEN_CODE_200(200,"Success"),
    INA_CANTEEN_CODE_201(201,"No Data Found"),
    INA_CANTEEN_CODE_202(202,"Data Already Present in DB, Kindly add another Data"),
    INA_CANTEEN_CODE_99999(99999,"Technical Error"),
    INA_CANTEEN_CODE_203(203,"Customer Deleted Successfully"),
    INA_CANTEEN_CODE_204(204,"Customer Data updated in DB Successfully");




    private final int key;
    private final String value;

    ResponseCode(int key, String value) {
        this.key = key;
        this.value = value;
    }

    public int getKey() {
        return key;
    }

    public String getValue() {
        return value;
    }
}
