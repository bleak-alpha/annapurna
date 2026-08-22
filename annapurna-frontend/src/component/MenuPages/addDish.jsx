import { useState } from "react";

function AddDish() {
  const [form, setForm] = useState({
    itemCode: "",
    itemNumber: "",
    itemDescription: "",
    cost: "",
    inUse: false,
    isActive: false,
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;

    setForm({
      ...form,
      [name]: type === "checkbox" ? checked : value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const { addMenu } = await import('../../api/api.js');
      const response = await addMenu(form);
      console.log('Success:', response);
      alert('Dish added successfully!');
      setForm({
        itemCode: '',
        itemNumber: '',
        itemDescription: '',
        cost: '',
        inUse: false,
        isActive: false,
      });
    } catch (error) {
      console.error('Error:', error);
      alert('Failed to add dish: ' + error.message);
    }
  };

  return (  
    <div>
      <h2>Add Dish Form</h2>

      <form onSubmit={handleSubmit}>
        <input name="itemCode" placeholder="Item Code" value={form.itemCode} onChange={handleChange} />
        <input name="itemNumber" placeholder="Item Number" value={form.itemNumber} onChange={handleChange} />
        <input name="itemDescription" placeholder="Item Description" value={form.itemDescription} onChange={handleChange} />
        <input name="cost" placeholder="Cost" value={form.cost} onChange={handleChange} />


        <label>
          In Use
          <input
            type="checkbox"
            name="inUse"
            checked={form.inUse}
            onChange={handleChange}
          />
        </label>

        <label>
          Is Active
          <input
            type="checkbox"
            name="isActive"
            checked={form.isActive}
            onChange={handleChange}
          />
        </label>

        <button type="submit">Save</button>
      </form>
    </div>
  );
}

export default AddDish;