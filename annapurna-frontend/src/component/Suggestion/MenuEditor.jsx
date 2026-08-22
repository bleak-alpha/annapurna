import React, { useState } from "react";

const MenuEditor = (props) => {
  const menu = props.menu || [];

  const [search, setSearch] = useState("");
  const [selectedDish, setSelectedDish] = useState(null);
  const [qty, setQty] = useState("");
  const [selectedOrders, setSelectedOrders] = useState(
    Array.isArray(props.value) ? props.value : []);
  const suggestions =
    search.trim() === ""
      ? []
      : menu.filter((item) =>
        item.itemDescription
          ?.toLowerCase()
          .includes(search.toLowerCase())
      );


  console.log(menu);

  const addDish = () => {
    if (!selectedDish) {
      alert("Please select a dish.");
      return;
    }

    if (!qty || Number(qty) <= 0) {
      alert("Enter valid quantity.");
      return;
    }

    // Check if dish already exists
    const existingIndex = selectedOrders.findIndex(
      (order) => order.itemId === selectedDish.itemId
    );

    let updatedOrders = [...selectedOrders];

    console.log("Existing Index:", existingIndex);
    console.log("Updated Orders:", updatedOrders);



    if (existingIndex !== -1) {
      updatedOrders[existingIndex].qty =
        Number(updatedOrders[existingIndex].qty) + Number(qty);
    } else {
      updatedOrders.push({
        itemId: selectedDish.itemId,
        itemDescription: selectedDish.itemDescription,
        cost: Number(selectedDish.cost),
        qty: Number(qty),
        served: false,
      });
    }

    setSelectedOrders(updatedOrders);

    setSearch("");
    setSelectedDish(null);
    setQty("");
  };

  const increaseQty = (index) => {
    const updatedOrders = [...selectedOrders];
    updatedOrders[index].qty += 1;
    setSelectedOrders(updatedOrders);
  };

  const decreaseQty = (index) => {
    const updatedOrders = [...selectedOrders];

    if (updatedOrders[index].qty > 1) {
      updatedOrders[index].qty -= 1;
      setSelectedOrders(updatedOrders);
    } else {
      // Remove item if quantity becomes 0
      removeDish(index);
    }
  };

  const removeDish = (index) => {
    setSelectedOrders(selectedOrders.filter((_, i) => i !== index));
  };

  console.log("Selected Orders is :", selectedOrders);


  // const total = selectedOrders.reduce(
  //   (sum, item) => sum + item.cost * item.qty,
  //   0
  // );

  // console.log("item cost is ", selectedOrders[0]?.cost);
  // console.log("item qty is ", selectedOrders[0]?.qty);

  // console.log("total amount is " + total);

  const saveOrder = () => {
    const total = selectedOrders.reduce(
      (sum, item) => sum + Number(item.cost) * Number(item.qty),
      0
    );

    console.log("Selected Orders:", selectedOrders);
    console.log("Total Payment:", total);

    props.node.setDataValue("orders", selectedOrders);
    props.node.setDataValue("totalPayment", total);

    console.log("Total =", total);

    props.api.refreshCells({
      rowNodes: [props.node],
      force: true,
    });

    props.stopEditing();

    console.log("Total =", total);


  };

  return (
    <div
      style={{
        width: 380,
        background: "#fff",
        padding: 12,
        border: "1px solid #ccc",
        borderRadius: 6,

        maxHeight: "70vh",   // Maximum popup height
        overflowY: "auto",   // Scroll inside popup
        boxSizing: "border-box",
      }}

    >
      <h4>Selected Dishes</h4>

      {selectedOrders.length === 0 && (
        <div>No Dish Added</div>
      )}

      {selectedOrders.map((order, index) => (
        <div
          key={index}
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 8,
            padding: "6px 0",
          }}
        >
          <div style={{ flex: 1 }}>
            {order.itemDescription}
          </div>

          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
            }}
          >
            <button
              onClick={() => decreaseQty(index)}
              style={{
                width: 28,
                height: 28,
                borderRadius: "50%",
                border: "none",
                background: "#1976d2",
                color: "#fff",
                fontSize: 18,
                cursor: "pointer",
              }}
            >
              −
            </button>

            <span
              style={{
                minWidth: 20,
                textAlign: "center",
                fontWeight: "bold",
              }}
            >
              {order.qty}
            </span>

            <button
              onClick={() => increaseQty(index)}
              style={{
                width: 28,
                height: 28,
                borderRadius: "50%",
                border: "none",
                background: "#1976d2",
                color: "#fff",
                fontSize: 18,
                cursor: "pointer",
              }}
            >
              +
            </button>

            <button
              onClick={() => removeDish(index)}
              style={{
                marginLeft: 8,
                background: "red",
                color: "white",
                border: "none",
                borderRadius: 4,
                cursor: "pointer",
                padding: "4px 8px",
              }}
            >
              ✕
            </button>
          </div>
        </div>
      ))}
      <hr />

      <input
        autoFocus
        placeholder="Search Dish"
        value={search}
        onChange={(e) => {
          setSearch(e.target.value);
          setSelectedDish(null);
        }}
        style={{
          width: "100%",
          padding: 8,
          marginBottom: 8,
        }}
      />

      {suggestions.length > 0 && (
        <div
          style={{
            maxHeight: 120,
            overflowY: "auto",
            border: "1px solid #ccc",
            marginBottom: 10,
          }}
        >
          {suggestions.map((item) => (
            <div
              key={item.itemId}
              onClick={() => {
                const existingIndex = selectedOrders.findIndex(
                  (order) => order.itemId === item.itemId
                );

                let updatedOrders = [...selectedOrders];

                if (existingIndex !== -1) {
                  updatedOrders[existingIndex].qty += 1;
                } else {
                  updatedOrders.push({
                    itemId: item.itemId,
                    itemDescription: item.itemDescription,
                    cost: Number(item.cost),
                    qty: 1,
                    served: false,
                  });
                }

                setSelectedOrders(updatedOrders);
                setSearch("");
                setSelectedDish(null);
              }}
              style={{
                padding: 8,
                cursor: "pointer",
                borderBottom: "1px solid #eee",
              }}
            >
              {item.itemDescription} (₹{item.cost})
            </div>
          ))}
        </div>
      )}

      {selectedDish && (
        <>
          <div
            style={{
              marginBottom: 8,
              color: "green",
              fontWeight: "bold",
            }}
          >
            Selected : {selectedDish.itemDescription}
          </div>

          <input
            type="number"
            placeholder="Enter Quantity"
            value={qty}
            onChange={(e) => setQty(e.target.value)}
            style={{
              width: "100%",
              padding: 8,
              marginBottom: 10,
            }}
          />

          <button
            onClick={addDish}
            style={{
              width: "100%",
              padding: 8,
              marginBottom: 10,
              background: "#1976d2",
              color: "white",
              border: "none",
              cursor: "pointer",
            }}
          >
            Add Dish
          </button>
        </>
      )}

      <hr />



      <button
        onClick={saveOrder}
        style={{
          width: "100%",
          padding: 10,
          background: "green",
          color: "white",
          border: "none",
          cursor: "pointer",
          fontWeight: "bold",
        }}
      >
        Save Order
      </button>
    </div>
  );
};

export default MenuEditor;