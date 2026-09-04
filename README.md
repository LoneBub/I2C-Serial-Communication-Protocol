# I2C

**Overview**

I2C (Inter-Integrated Circuit) is a synchronous, two-wire communication protocol used for communication between a Master and one or more Slave devices.

I2C uses two signals:

- SDA - Serial Data
- SCL - Serial Clock

The basic communication sequence is:

<img width="192" height="547" alt="image" src="https://github.com/user-attachments/assets/b5865880-aecd-454c-9cd3-291492dbd4f1" />

I2C Communication Sequence

**1. START Condition**

The Master begins communication by generating a START condition.

A START condition occurs when:

- SDA: HIGH -> LOW
- SCL: HIGH


The Master pulls SDA from HIGH to LOW while SCL is HIGH.
          
<img width="262" height="142" alt="image" src="https://github.com/user-attachments/assets/1e0698d2-64cf-4bde-9075-e83743e20557" />


**2. Slave Address**

After the START condition, the Master sends the Slave address.

A standard I2C Slave address is normally 7 bits.

For example: Slave Address = 0x50

Binary = 1010000

**3. Read / Write Bit**

After the 7-bit Slave address, the Master sends the R/W bit.

- R/W = 0  ->  WRITE
- R/W = 1  ->  READ


The address byte is therefore:

<img width="292" height="98" alt="image" src="https://github.com/user-attachments/assets/2fb2e314-500a-4936-86bc-a61fd6b71e81" />



**4. Slave Acknowledgement (ACK)**

After receiving the Slave address and R/W bit, the Slave responds with an ACK.

Each I2C byte consists of:

8 Data Bits + 1 ACK/NACK Bit

The ACK is transmitted during the 9th clock pulse.

<img width="307" height="100" alt="image" src="https://github.com/user-attachments/assets/0ee648c6-d439-45fd-8549-e00b1c0c4d9f" />

An ACK is indicated by:

SDA = LOW


A NACK is indicated by:

SDA = HIGH

**5. Data Transfer**

After the Slave acknowledges the address, data transfer begins.

Each data byte contains 8 bits, followed by an ACK/NACK.

**Write Operation**

During a WRITE operation, the Master sends data to the Slave.

<img width="357" height="386" alt="image" src="https://github.com/user-attachments/assets/cf716269-22b6-4496-8140-bfc3bf464d53" />

The sequence is:

<img width="155" height="547" alt="image" src="https://github.com/user-attachments/assets/869fde78-9882-4a64-9bff-c7bb122cf7f8" />


**Read Operation**

During a READ operation, the Slave sends data to the Master.

<img width="366" height="482" alt="image" src="https://github.com/user-attachments/assets/46127613-ea11-4c1c-9966-1dfbaddd707e" />

The Master sends ACK when it wants to receive more data.

The Master sends NACK after the final data byte to indicate that it does not want any more data.

**6. Acknowledgement**

I2C uses an ACK/NACK bit after every transmitted byte.

- ACK

SDA = LOW


ACK means:

"Byte received successfully."


Communication can continue.

- NACK
  
SDA = HIGH


NACK means:

"Byte was not acknowledged or no more data is required."

**7. STOP Condition**

When the communication is complete, the Master generates a STOP condition.

A STOP condition occurs when:

- SDA: LOW -> HIGH
- SCL: HIGH


The Master releases SDA from LOW to HIGH while SCL is HIGH.

<img width="262" height="171" alt="image" src="https://github.com/user-attachments/assets/0b6a51b0-c928-421e-9f4f-ef3583ae6e28" />

The STOP condition indicates that the current I2C transaction has ended.

**8. IDLE State**

After the STOP condition, the I2C bus returns to the IDLE state.

During IDLE:

- SDA = HIGH
- SCL = HIGH

<img width="332" height="87" alt="image" src="https://github.com/user-attachments/assets/295acb0a-330d-47cd-b7cb-406d777abed4" />



Both SDA and SCL are normally pulled HIGH using pull-up resistors.

Complete I2C Transaction

The complete basic transaction can be represented as:

<img width="137" height="571" alt="image" src="https://github.com/user-attachments/assets/1a0094aa-4681-4151-999e-c915a7da5948" />


I2C Frame Format

A simplified I2C write frame:

<img width="342" height="320" alt="image" src="https://github.com/user-attachments/assets/7798539c-f63c-4dc7-aa4f-4350215c7da2" />


A simplified I2C read frame:

<img width="387" height="335" alt="image" src="https://github.com/user-attachments/assets/c33a46d8-955e-40e3-84ec-adf69ff14538" />

**Important Points**
- I2C uses two communication lines: SDA and SCL.
- SDA carries the data.
- SCL carries the clock.
- The Master controls SCL.
- A START condition begins communication.
- The Master sends the 7-bit Slave address.
- The R/W bit determines the operation.
- R/W = 0 means WRITE.
- R/W = 1 means READ.
- The receiver generates ACK/NACK.
- Each data transfer consists of 8 bits + 1 ACK/NACK bit.
- During WRITE, the Master sends data.
- During READ, the Slave sends data.
- The Master sends NACK after the final byte of a read.
- A STOP condition ends the transaction.
- After STOP, the bus returns to IDLE.
- During IDLE, SDA and SCL are HIGH.



This sequence forms the foundation of I2C communication between a Master and Slave device.
