We have:

Order Controller (Presenter) (post-data, form objects, redirects, services)
|- Create Order Service
   |- Create Mapper -> StorageAdapter -> Use Case
      |- Create Order Use Case
         |- StorageAdapter -> save -> Mapper -> save + related (Transaction)

Where does Save Order with new contact go (opposed to with an existing contact)
Is it a different use case?
Yes it is.
