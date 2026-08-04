  import React, { useState, useImperativeHandle, forwardRef } from "react";

  const CustomerEditor = forwardRef((props, ref) => {
    const [value, setValue] = useState(props.value || "");
    const customers = props.customers || [];

    console.log("CustomerEditor props:", props);
    console.log("Customer Input :", value);

    const suggestions =
      value.trim().length === 0
        ? []
        : customers.filter((c) =>
            c.name?.toLowerCase().startsWith(value.toLowerCase())
          );

    useImperativeHandle(ref, () => ({
      getValue() {
          console.log("getValue:", value);

        const existingCustomer = customers.find(
          (c) => c.name?.toLowerCase() === value.trim().toLowerCase()
        );

        if (existingCustomer) {
          return existingCustomer.name;
        }

        return value.trim();
        console.log("getValue input value if not found in suggestion:", value);
      },

      isCancelAfterEnd() {
        return false;
      },
    }));

    // =========================
    // HANDLE SAVE (Enter key)
    // =========================
    const handleSave = () => {
        console.log("handleSave:", value);

      if (!value.trim()) {
        props.stopEditing(true);
        return;
      }

      const existingCustomer = customers.find(
        (c) => c.name?.toLowerCase() === value.trim().toLowerCase()
      );

      if (existingCustomer) {
        // Existing customer found
        props.node.setDataValue("customerId", existingCustomer.customerNumber);
        props.node.setDataValue("customerName", existingCustomer.name);
      } else {
        // New customer - save as TEMP
        props.node.setDataValue("customerId", `TEMP-${Date.now()}`);
        props.node.setDataValue("customerName", value.trim());
      }

 
    };

    // =========================
    // HANDLE SUGGESTION SELECT
    // =========================
    const handleSuggestionSelect = (customer) => {
      console.log("Selecting suggestion:", customer.name);

      // Update local state
      setValue(customer.name);

      // Set both customer ID and name
      props.node.setDataValue("customerId", customer.customerNumber);
      props.node.setDataValue("customerName", customer.name);

      // Stop editing
      props.stopEditing();
    };

    return (
      <div
        style={{
          position: "relative",
          width: "250px",
          overflow: "visible",
        }}
      >
        <input
          autoFocus
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              handleSave();
            } else if (e.key === "Escape") {
              props.stopEditing(true);
            }
          }}
          placeholder="Enter customer name"
          style={{
            width: "100%",
            padding: "8px",
            border: "1px solid #ccc",
            boxSizing: "border-box",
            borderRadius: "4px",
          }}
        />

        {/* Suggestions Dropdown */}
        {suggestions.length > 0 && (
          <div
            style={{
              position: "absolute",
              top: "40px",
              left: 0,
              width: "100%",
              maxHeight: "200px",
              overflowY: "auto",
              background: "white",
              border: "1px solid #ccc",
              borderTop: "none",
              borderRadius: "0 0 4px 4px",
              zIndex: 99999,
              boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
            }}
          >
            {suggestions.map((c) => (
              <div
                key={c.customerNumber}
                style={{
                  padding: "10px 12px",
                  cursor: "pointer",
                  borderBottom: "1px solid #eee",
                  transition: "background 0.15s ease",
                  userSelect: "none",
                }}
                onMouseEnter={(e) => (e.target.style.background = "#f5f5f5")}
                onMouseLeave={(e) => (e.target.style.background = "white")}
                onMouseDown={(e) => {
                  e.preventDefault();
                  handleSuggestionSelect(c);
                }}
              >
                <strong>{c.name}</strong>
                {c.customerNumber && (
                  <span style={{ fontSize: "12px", color: "#999", marginLeft: "8px" }}>
                    (ID: {c.customerNumber})
                  </span>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    );
  });

  CustomerEditor.displayName = "CustomerEditor";

  export default CustomerEditor;