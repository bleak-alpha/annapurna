import { useState } from "react";

function AddCustomer() {
const [form, setForm] = useState({
    name: "",
    phone : ""
})

const handleChange = (e) => {
    const { name, value } = e.target;
    setForm({
        ...form,
        [name]: value
    })
};

const handleSubmit = async (e) => {
    e.preventDefault();

try {
    const { addCustomer } = await import('../../api/api.js');
    const response = await addCustomer(form);
    console.log('Success:', response);
    alert('Customer added successfully!');
    setForm({
        name: '',
        phone: ''
    });
} catch (error) {
    console.error('Error:', error);
    alert('Failed to add customer: ' + error.message);
}
}
return (
    <div>
        <h2>Add Customer Form</h2>
        <form onSubmit={handleSubmit}>
            <input name="name" placeholder="Name" value={form.name} onChange={handleChange} />
            <input name="phone" placeholder="Phone" value={form.phone} onChange={handleChange} />
            <button type="submit">Save</button>
        </form>
    </div>
);
}
export default AddCustomer;
